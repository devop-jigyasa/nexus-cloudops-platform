terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Production backend using remote S3 state and DynamoDB locking
  # backend "s3" {
  #   bucket         = "nexus-prod-terraform-state-backend"
  #   key            = "platform/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "nexus-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "Nexus-CloudOps"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
  vpc_cidr    = "10.0.0.0/16"
}

module "security" {
  source      = "../../modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = "nexus-${var.environment}-artifacts-${var.aws_region}"
  environment = var.environment
}

module "iam" {
  source        = "../../modules/iam"
  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}
