terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }

  required_version = ">= 1.13"
}

provider "aws" {
  region = "eu-west-2"
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "microtodo_tf_state" {
  bucket = "microtodo-tf-state-${random_id.suffix.hex}"

  tags = {
    Name = "microtodo-tf-state"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "microtodo_tf_state_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.microtodo_tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "microtodo_tf_state_versioning" {
  bucket = aws_s3_bucket.microtodo_tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "microtodo_tf_state_lock" {
  name         = "microtodo-tf-state-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "microtodo-tf-state-lock"
  }
}

output "terraform_state_bucket" {
  value       = aws_s3_bucket.microtodo_tf_state.id
  description = "ID of the S3 bucket storing Terraform state"
}

output "terraform_state_bucket_arn" {
  value       = aws_s3_bucket.microtodo_tf_state.arn
  description = "ARN of the S3 bucket storing Terraform state"
}

output "terraform_lock_table_name" {
  value       = aws_dynamodb_table.microtodo_tf_state_lock.name
  description = "Name of the DynamoDB table used for Terraform state locking"
}

output "terraform_lock_table_arn" {
  value       = aws_dynamodb_table.microtodo_tf_state_lock.arn
  description = "ARN of the DynamoDB table used for Terraform state locking"
}
