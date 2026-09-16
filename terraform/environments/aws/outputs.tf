output "vpc_id" {
  value = module.vpc.vpc_id
}

output "s3_bucket" {
  value = module.s3.bucket_id
}
