#!/bin/bash
set -e
echo "Initializing LocalStack AWS Mock Resources..."

# S3 Bucket creation
awslocal s3 mb s3://nexus-platform-artifacts || true
awslocal s3 mb s3://nexus-terraform-state-backend || true

# DynamoDB Lock Table for Terraform State
awslocal dynamodb create-table \
    --table-name nexus-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST || true

echo "LocalStack Resources Provisioned Successfully."
