terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = var.aws_region
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    s3       = var.localstack_endpoint
    iam      = var.localstack_endpoint
    ec2      = var.localstack_endpoint
    sts      = var.localstack_endpoint
    dynamodb = var.localstack_endpoint
  }
}

module "vpc" {
  source      = "../../modules/vpc"
  environment = var.environment
  vpc_cidr    = "10.100.0.0/16"
}

module "security" {
  source      = "../../modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "s3" {
  source      = "../../modules/s3"
  bucket_name = "nexus-local-artifacts"
  environment = var.environment
}

module "iam" {
  source        = "../../modules/iam"
  environment   = var.environment
  s3_bucket_arn = module.s3.bucket_arn
}
