output "role_arn" {
  value = aws_iam_role.app_workload_role.arn
}

output "policy_arn" {
  value = aws_iam_policy.s3_access_policy.arn
}
