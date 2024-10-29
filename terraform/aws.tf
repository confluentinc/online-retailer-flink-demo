# default security group in the desired VPC
data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "db_security_group" {
  name   = "db_sg_${random_id.env_display_id.hex}"
  vpc_id = data.aws_vpc.default.id
}

#  rule to the default security group
resource "aws_security_group_rule" "allow_inbound_postgres" {
  type              = "ingress"
  from_port         = 5432              
  to_port           = 5432              
  protocol          = "tcp"
  security_group_id = aws_security_group.db_security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_outbound_postgres" {
  type              = "egress"
  from_port         = 5432              
  to_port           = 5432              
  protocol          = "tcp"
  security_group_id = aws_security_group.db_security_group.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_db_instance" "postgres_db" {
  allocated_storage    = 30
  engine             = "postgres"
  engine_version     = "16.4"
  instance_class     = "db.t3.medium"
  identifier         = "${var.prefix}-onlinestoredb-${random_id.env_display_id.hex}"
  db_name = "onlinestoredb"
  username           = var.db_username
  password           = var.db_password
  publicly_accessible = true
  parameter_group_name = aws_db_parameter_group.pg_parameter_group.name
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  apply_immediately    = true
  skip_final_snapshot = true
}


resource "aws_db_parameter_group" "pg_parameter_group" {
  name   = "${var.prefix}-rds-pg-debezium-${random_id.env_display_id.hex}"
  family = "postgres16"

  parameter {
    apply_method = "pending-reboot"
    name  = "rds.logical_replication"
    value = 1
  }
}

# Create the database tables using a local-exec provisioner
resource "null_resource" "create_tables" {
  depends_on = [aws_db_instance.postgres_db]

  provisioner "local-exec" {
    command = <<EOT
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres_db.address} -p ${aws_db_instance.postgres_db.port} -U ${aws_db_instance.postgres_db.username} -d ${aws_db_instance.postgres_db.db_name} -c "
      CREATE TABLE IF NOT EXISTS products (
          ProductID INT PRIMARY KEY,
          Brand VARCHAR(255) NOT NULL,
          ProductName VARCHAR(255) NOT NULL,
          Category VARCHAR(100) NOT NULL,
          Description TEXT,
          Color VARCHAR(50),
          Size VARCHAR(50),
          Price DECIMAL(10, 2) NOT NULL,
          Stock INT NOT NULL
      );"
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres_db.address} -p ${aws_db_instance.postgres_db.port} -U ${aws_db_instance.postgres_db.username} -d ${aws_db_instance.postgres_db.db_name} -c "
      CREATE TABLE IF NOT EXISTS customers (
          CustomerID INT PRIMARY KEY,
          CustomerName VARCHAR(255) NOT NULL,
          Email VARCHAR(255) NOT NULL UNIQUE,
          Segment VARCHAR(50) NOT NULL,
          Address VARCHAR(255) NOT NULL
      );"
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres_db.address} -p ${aws_db_instance.postgres_db.port} -U ${aws_db_instance.postgres_db.username} -d ${aws_db_instance.postgres_db.db_name} -c "
      CREATE TABLE IF NOT EXISTS orders (
          OrderID INT PRIMARY KEY,
          CustomerID INT NOT NULL,
          OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          Status VARCHAR(50) NOT NULL,
          FOREIGN KEY (CustomerID) REFERENCES customers(CustomerID)
      );"
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres_db.address} -p ${aws_db_instance.postgres_db.port} -U ${aws_db_instance.postgres_db.username} -d ${aws_db_instance.postgres_db.db_name} -c "
      CREATE TABLE IF NOT EXISTS order_items (
          OrderItemID INT PRIMARY KEY,
          OrderID INT NOT NULL,
          ProductID INT NOT NULL,
          Quantity INT NOT NULL,
          FOREIGN KEY (OrderID) REFERENCES orders(OrderID),
          FOREIGN KEY (ProductID) REFERENCES products(ProductID)
      );"
    EOT
  }
}


# ------------------------------------------------------
# KMS Key for CSFLE
# ------------------------------------------------------

data "aws_caller_identity" "current" {}

resource "aws_kms_alias" "kms_key_alias" {
  name          = "alias/${var.prefix}_csfle_key_${random_id.env_display_id.hex}"
  target_key_id = aws_kms_key.kms_key.key_id
}

resource "aws_kms_key" "kms_key" {
  description    = "An symmetric encryption KMS key used for CSFLE"
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1-${random_id.env_display_id.hex}"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "${data.aws_caller_identity.current.arn}"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid    = "Enable Any IAM User Permission to DESCRIBE"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        },
        Action   = [
            "kms:DescribeKey",
            "kms:GetKeyPolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "${aws_iam_user.payments_app_user.arn}"
        },
        Action = [
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey",
          "kms:GenerateDataKeyWithoutPlaintext"
        ],
        Resource = "*"
      }
    ]
  })
}
