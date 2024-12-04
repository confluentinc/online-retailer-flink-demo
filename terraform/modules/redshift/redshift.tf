# Create a Redshift subnet group
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "${var.prefix}-redshift-subnet-group-${var.random_id}"
  subnet_ids = [var.subnet_id]  # Pass in the subnet IDs for your Redshift cluster
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier = "${var.prefix}-redshift-${var.random_id}"
  database_name      = "mydb"
  master_username    = "admin"
  master_password    = "Admin123456!"
  node_type          = "ra3.large"
  cluster_type       = "single-node"
  vpc_security_group_ids = [aws_security_group.redshift_sg.id]
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift_subnet_group.name
  iam_roles          = [aws_iam_role.redshift_role.arn]
  skip_final_snapshot = true
}


# Create an IAM role for the Redshift cluster to access other AWS services
resource "aws_iam_role" "redshift_role" {
  name = "${var.prefix}-redshift-role-${var.random_id}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# Attach the AmazonS3ReadOnlyAccess policy to the Redshift IAM role
resource "aws_iam_role_policy_attachment" "redshift_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role       = aws_iam_role.redshift_role.name
}


resource "aws_security_group" "redshift_sg" {
  name        = "${var.prefix}-redshift-sg-${var.random_id}"
  description = "Redshift security group"
  vpc_id      = var.vpc_id
}

# Allow access from specific IP addresses or security groups (optional)
resource "aws_security_group_rule" "allow_ingress" {
  type              = "ingress"
  from_port         = 5439  # Default Redshift port
  to_port           = 5439
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Replace with your network CIDR block
  security_group_id = aws_security_group.redshift_sg.id
}
