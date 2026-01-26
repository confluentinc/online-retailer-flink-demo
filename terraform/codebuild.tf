# -------------------------------
# CodeBuild Infrastructure
# Builds and pushes container images to ECR
# -------------------------------

# -------------------------------
# S3 Bucket for Source Code
# -------------------------------

resource "aws_s3_bucket" "codebuild_source" {
  bucket        = "${var.prefix}-codebuild-source-${random_id.env_display_id.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "codebuild_source" {
  bucket = aws_s3_bucket.codebuild_source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -------------------------------
# IAM Role for CodeBuild
# -------------------------------

resource "aws_iam_role" "codebuild_role" {
  name = "${var.prefix}-codebuild-role-${random_id.env_display_id.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.prefix}-codebuild-policy-${random_id.env_display_id.hex}"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.codebuild_source.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [
          aws_ecr_repository.payment_app_repo.arn,
          aws_ecr_repository.dbfeeder_app_repo.arn
        ]
      }
    ]
  })
}

# -------------------------------
# CodeBuild Projects
# -------------------------------

resource "aws_codebuild_project" "payment_app" {
  name         = "${var.prefix}-payment-app-build-${random_id.env_display_id.hex}"
  description  = "Build and push Payment App container image to ECR"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true  # Required for container builds
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.payment_app_repo.repository_url
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.cloud_region
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.codebuild_source.bucket}/payments-app.zip"
    buildspec = <<-EOF
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
        build:
          commands:
            - echo Building Docker image...
            - docker build -t $ECR_REPO_URL:latest .
            - docker tag $ECR_REPO_URL:latest $ECR_REPO_URL:$CODEBUILD_BUILD_NUMBER
        post_build:
          commands:
            - echo Pushing Docker image...
            - docker push $ECR_REPO_URL:latest
            - docker push $ECR_REPO_URL:$CODEBUILD_BUILD_NUMBER
            - echo Build completed on `date`
            - printf '{"imageUri":"%s"}' $ECR_REPO_URL:latest > imageDetail.json
      artifacts:
        files:
          - imageDetail.json
    EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.prefix}-payment-app"
      stream_name = "build-log"
    }
  }
}

resource "aws_codebuild_project" "dbfeeder_app" {
  name         = "${var.prefix}-dbfeeder-app-build-${random_id.env_display_id.hex}"
  description  = "Build and push DB Feeder App container image to ECR"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "ECR_REPO_URL"
      value = aws_ecr_repository.dbfeeder_app_repo.repository_url
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.cloud_region
    }
  }

  source {
    type      = "S3"
    location  = "${aws_s3_bucket.codebuild_source.bucket}/dbfeeder-app.zip"
    buildspec = <<-EOF
      version: 0.2
      phases:
        pre_build:
          commands:
            - echo Logging in to Amazon ECR...
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
        build:
          commands:
            - echo Building Docker image...
            - docker build -t $ECR_REPO_URL:latest .
            - docker tag $ECR_REPO_URL:latest $ECR_REPO_URL:$CODEBUILD_BUILD_NUMBER
        post_build:
          commands:
            - echo Pushing Docker image...
            - docker push $ECR_REPO_URL:latest
            - docker push $ECR_REPO_URL:$CODEBUILD_BUILD_NUMBER
            - echo Build completed on `date`
            - printf '{"imageUri":"%s"}' $ECR_REPO_URL:latest > imageDetail.json
      artifacts:
        files:
          - imageDetail.json
    EOF
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.prefix}-dbfeeder-app"
      stream_name = "build-log"
    }
  }
}

# -------------------------------
# Upload Source and Trigger Builds
# -------------------------------
# Note: Uses data.aws_caller_identity.current from aws.tf

# Create zip archives of the source code
data "archive_file" "payment_app_source" {
  type        = "zip"
  source_dir  = "${path.module}/../code/payments-app"
  output_path = "${path.module}/.build/payments-app.zip"

  depends_on = [
    local_file.payment_app_properties,
    local_file.payment_app_dqr
  ]
}

data "archive_file" "dbfeeder_app_source" {
  type        = "zip"
  source_dir  = "${path.module}/../code/postgresql-data-feeder"
  output_path = "${path.module}/.build/dbfeeder-app.zip"

  depends_on = [
    local_file.db_feeder_properties
  ]
}

# Upload source code to S3
resource "aws_s3_object" "payment_app_source" {
  bucket = aws_s3_bucket.codebuild_source.id
  key    = "payments-app.zip"
  source = data.archive_file.payment_app_source.output_path
  etag   = data.archive_file.payment_app_source.output_md5
}

resource "aws_s3_object" "dbfeeder_app_source" {
  bucket = aws_s3_bucket.codebuild_source.id
  key    = "dbfeeder-app.zip"
  source = data.archive_file.dbfeeder_app_source.output_path
  etag   = data.archive_file.dbfeeder_app_source.output_md5
}

# Trigger CodeBuild for Payment App
resource "null_resource" "build_payment_app" {
  triggers = {
    source_hash = data.archive_file.payment_app_source.output_md5
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting CodeBuild for Payment App..."
      BUILD_ID=$(aws codebuild start-build \
        --project-name ${aws_codebuild_project.payment_app.name} \
        --region ${var.cloud_region} \
        --query 'build.id' \
        --output text)

      echo "Build started: $BUILD_ID"
      echo "Waiting for build to complete..."

      # Wait for build to complete (timeout after 10 minutes)
      TIMEOUT=600
      ELAPSED=0
      while [ $ELAPSED -lt $TIMEOUT ]; do
        STATUS=$(aws codebuild batch-get-builds \
          --ids $BUILD_ID \
          --region ${var.cloud_region} \
          --query 'builds[0].buildStatus' \
          --output text)

        if [ "$STATUS" = "SUCCEEDED" ]; then
          echo "Build succeeded!"
          exit 0
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "FAULT" ] || [ "$STATUS" = "STOPPED" ] || [ "$STATUS" = "TIMED_OUT" ]; then
          echo "Build failed with status: $STATUS"
          exit 1
        fi

        echo "Build status: $STATUS (waiting...)"
        sleep 10
        ELAPSED=$((ELAPSED + 10))
      done

      echo "Build timed out after $TIMEOUT seconds"
      exit 1
    EOT
  }

  depends_on = [
    aws_s3_object.payment_app_source,
    aws_codebuild_project.payment_app,
    aws_ecr_repository.payment_app_repo
  ]
}

# Trigger CodeBuild for DB Feeder App
resource "null_resource" "build_dbfeeder_app" {
  triggers = {
    source_hash = data.archive_file.dbfeeder_app_source.output_md5
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting CodeBuild for DB Feeder App..."
      BUILD_ID=$(aws codebuild start-build \
        --project-name ${aws_codebuild_project.dbfeeder_app.name} \
        --region ${var.cloud_region} \
        --query 'build.id' \
        --output text)

      echo "Build started: $BUILD_ID"
      echo "Waiting for build to complete..."

      # Wait for build to complete (timeout after 10 minutes)
      TIMEOUT=600
      ELAPSED=0
      while [ $ELAPSED -lt $TIMEOUT ]; do
        STATUS=$(aws codebuild batch-get-builds \
          --ids $BUILD_ID \
          --region ${var.cloud_region} \
          --query 'builds[0].buildStatus' \
          --output text)

        if [ "$STATUS" = "SUCCEEDED" ]; then
          echo "Build succeeded!"
          exit 0
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "FAULT" ] || [ "$STATUS" = "STOPPED" ] || [ "$STATUS" = "TIMED_OUT" ]; then
          echo "Build failed with status: $STATUS"
          exit 1
        fi

        echo "Build status: $STATUS (waiting...)"
        sleep 10
        ELAPSED=$((ELAPSED + 10))
      done

      echo "Build timed out after $TIMEOUT seconds"
      exit 1
    EOT
  }

  depends_on = [
    aws_s3_object.dbfeeder_app_source,
    aws_codebuild_project.dbfeeder_app,
    aws_ecr_repository.dbfeeder_app_repo,
    module.postgres
  ]
}

# -------------------------------
# Outputs for image URIs
# -------------------------------

output "payment_app_image_uri" {
  description = "ECR URI for Payment App image"
  value       = "${aws_ecr_repository.payment_app_repo.repository_url}:latest"
}

output "dbfeeder_app_image_uri" {
  description = "ECR URI for DB Feeder App image"
  value       = "${aws_ecr_repository.dbfeeder_app_repo.repository_url}:latest"
}
