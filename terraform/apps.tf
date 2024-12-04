resource "aws_iam_user" "payments_app_user" {
  name = "payments_app_user_${random_id.env_display_id.hex}"
}

resource "aws_iam_access_key" "payments_app_aws_key" {
  user = aws_iam_user.payments_app_user.name
}

locals {
  # Determine the CPU architecture based on the input variable
  cpu_architecture       = var.local_architecture == "arm64" || var.local_architecture == "aarch64" ? "ARM64" : "X86_64"
}


resource "aws_iam_user_policy" "payments_app_iam_policy" {
  name   = "payments_app_iam_policy__${random_id.env_display_id.hex}"
  user   = aws_iam_user.payments_app_user.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# Create and write the DB Feeder application.properties file to the appropriate path
resource "local_file" "db_feeder_properties" {
  filename = "../code/postgresql-data-feeder/src/main/resources/db.properties"
  content  = <<-EOT
    db.url=jdbc:postgresql://${aws_db_instance.postgres_db.address}/onlinestoredb
    db.user=${var.db_username}
    db.password=${var.db_password}
  EOT 
  }

# Create and write the Payments app application.properties file to the appropriate path
resource "local_file" "payment_app_properties" {
  filename = "../code/payments-app/src/main/resources/cc-orders.properties"
  content  = <<-EOT
#Environment: inventory_mgmt
#Cluster: inventory analytics
bootstrap.servers=${confluent_kafka_cluster.standard.bootstrap_endpoint}
security.protocol=SASL_SSL
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
num.partitions=6
replication.factor=3
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${confluent_api_key.app-manager-kafka-api-key.id}" password="${confluent_api_key.app-manager-kafka-api-key.secret}";


# Confluent Cloud Schema Registry
schema.registry.url=${data.confluent_schema_registry_cluster.sr-cluster.rest_endpoint}
schema.registry.basic.auth.user.info= ${confluent_api_key.app-manager-schema-registry-api-key.id}:${confluent_api_key.app-manager-schema-registry-api-key.secret}
basic.auth.credentials.source=USER_INFO

## Data quality rules 
#KMS Props
rule.executors._default_.param.access.key.id=${aws_iam_access_key.payments_app_aws_key.id}
rule.executors._default_.param.secret.access.key=${aws_iam_access_key.payments_app_aws_key.secret}
  EOT 
  }

# Create and write the Payments App Data Quality Rules file to the appropriate path
resource "local_file" "payment_app_dqr" {
  filename = "../code/payments-app/src/main/datacontracts/avro/payments-value-dqr.json"
  content  = <<-EOT
  {
    "metadata": {
        "tags": {
            "Sale.cc_number": [ "pci" ]
        }
    },
    "ruleSet": {
        "domainRules": [
            {
                "name": "pci_encrypt",
                "kind": "TRANSFORM",
                "mode": "WRITEREAD",
                "type": "ENCRYPT",
                "tags": ["pci"],
                "params": {
                    "encrypt.kek.name": "pci_encrypt_key",
                    "encrypt.kms.key.id": "${aws_kms_key.kms_key.arn}",
                    "encrypt.kms.type": "aws-kms"
                },
                "onFailure": "ERROR,NONE",
                "disabled": false
            },
            {
                "name": "validateConfirmationCode",
                "kind": "CONDITION",
                "mode": "WRITE",
                "type": "CEL",
                "expr": "message.confirmation_code.matches('^[A-Z0-9]{8}$')",
                "onFailure": "DLQ",
                "params": {
                    "dlq.topic": "error-payments",
                    "dlq.auto.flush": "true"
                }
            }
        ]
    }
}
  EOT 
  }

# -------------------------------
# Containers Networking
# -------------------------------

# -------------------------------
#  VPC and Subnets
# -------------------------------

# VPC
resource "aws_vpc" "ecs_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# -------------------------------
# Internet Gateway
# -------------------------------

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id
}


# -------------------------------
# Public Route Table
# -------------------------------

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # This route allows all outbound traffic
    gateway_id = aws_internet_gateway.igw.id  # Route to the Internet Gateway
  }
}

# -------------------------------
# Associate Public Route Table with Public Subnet
# -------------------------------

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}


# -------------------------------
# Security Group for ECS
# -------------------------------

resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.ecs_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# -------------------------------
# Create ECR Repositories
# -------------------------------

resource "aws_ecr_repository" "payment_app_repo" {
  name = "${var.prefix}-payment-app-repo-${random_id.env_display_id.hex}"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecr_repository" "dbfeeder_app_repo" {
  name = "${var.prefix}-dbfeeder-app-repo-${random_id.env_display_id.hex}"
  lifecycle {
    prevent_destroy = false
  }
}


# -------------------------------
#  Build and Push Docker Images for Both Apps
# -------------------------------

locals {
  payment_app_image_tag  = "${aws_ecr_repository.payment_app_repo.repository_url}:latest"
  dbfeeder_app_image_tag = "${aws_ecr_repository.dbfeeder_app_repo.repository_url}:latest"
}

# Build and Push Payment App
resource "null_resource" "build_and_push_payment_app" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.cloud_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.payment_app_repo.repository_url}
      docker build -t payment-app ../code/payments-app
      docker tag payment-app:latest ${local.payment_app_image_tag}
      docker push ${local.payment_app_image_tag}
    EOT
  }
  depends_on = [
    local_file.db_feeder_properties,
    local_file.payment_app_properties,
    local_file.payment_app_dqr,
    null_resource.create_tables,
  ]
}



# Build and Push DB Feeder App
resource "null_resource" "build_and_push_dbfeeder_app" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.cloud_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.dbfeeder_app_repo.repository_url}
      docker build -t dbfeeder-app ../code/postgresql-data-feeder
      docker tag dbfeeder-app:latest ${local.dbfeeder_app_image_tag}
      docker push ${local.dbfeeder_app_image_tag}
    EOT
  }
  depends_on = [
    local_file.db_feeder_properties,
    local_file.payment_app_properties,
    local_file.payment_app_dqr,
    null_resource.create_tables,
  ]
}


# -------------------------------
#  ECS Cluster
# -------------------------------

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.prefix}-esc-cluster-${random_id.env_display_id.hex}"
}

resource "aws_iam_role_policy" "kms_usage_policy" {
  name = "kms_usage_policy_${random_id.env_display_id.hex}"
  role = aws_iam_role.ecs_container_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole_${random_id.env_display_id.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ECS-task-execution-attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for the containers
resource "aws_iam_role" "ecs_container_role" {
  name = "ecsTaskRole_${random_id.env_display_id.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action    = "sts:AssumeRole"
      }
    ]
  })

}

# -------------------------------
# ECS Task Definitions and Services for Both Apps
# -------------------------------

resource "aws_cloudwatch_log_group" "dbfeeder-log-group" {
  name = "/ecs/db-feeder-task-${random_id.env_display_id.hex}"
}

resource "aws_cloudwatch_log_group" "payments-task-log-group" {
  name = "/ecs/payments-task-${random_id.env_display_id.hex}"
}



# Task Definition for Payment App
resource "aws_ecs_task_definition" "payment_app_task" {
  family                   = "payment-app-task-${random_id.env_display_id.hex}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_container_role.arn
  memory                   = "512"
  cpu                      = "256"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = local.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = "payment-app"
      image     = "${local.payment_app_image_tag}"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.payments-task-log-group.name
          awslogs-region        = "${var.cloud_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}


# Task Definition for DB Feeder App
resource "aws_ecs_task_definition" "dbfeeder_app_task" {
  family                   = "dbfeeder-app-task-${random_id.env_display_id.hex}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_container_role.arn
  memory                   = "512"
  cpu                      = "256"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = local.cpu_architecture
  }

  container_definitions = jsonencode([
    {
      name      = "dbfeeder-app"
      image     = "${local.dbfeeder_app_image_tag}"
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.dbfeeder-log-group.name
          awslogs-region        = "${var.cloud_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}


# ECS Service for Payment App
resource "aws_ecs_service" "payment_app_service" {
  name            = "payment-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.payment_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
  null_resource.build_and_push_payment_app,
  confluent_kafka_topic.error-payments-topic,
  confluent_kafka_topic.payments-topic,
  confluent_schema.avro-payments
  ]
}



# ECS Service for DB Feeder App
resource "aws_ecs_service" "dbfeeder_app_service" {
  name            = "dbfeeder-app-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.dbfeeder_app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    null_resource.build_and_push_dbfeeder_app,
    null_resource.create_tables
    ]
}
