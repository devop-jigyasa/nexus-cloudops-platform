resource "aws_iam_role" "app_workload_role" {
  name = "nexus-${var.environment}-workload-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "nexus-${var.environment}-workload-role"
    Environment = var.environment
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "nexus-${var.environment}-s3-least-privilege"
  description = "Allows read/write access only to dedicated nexus artifact bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.app_workload_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
