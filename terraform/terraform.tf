terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.14"
    }
  }

  required_version = ">= 1.13"

  # We use S3 and DynamoDB as state storage (backend) so terraform can be ran in CI servers.
  backend "s3" {
    bucket         = "microtodo-tf-state" # Depends on the output from terraform-bootstrap
    key            = "microtodo/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "microtodo-tf-state-lock" # Depends on the output from terraform-bootstrap
    encrypt        = true
  }
}
