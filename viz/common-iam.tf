resource "aws_iam_policy" "write_read_access_viz_secrets_policy" {
  count = local.sandbox_resource_count
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret"
        ],
        Effect   = "Allow"
        Resource = var.secret_dockerhub_arn
      },
    ]
  })
}

data "aws_iam_policy" "selected" {
  arn = var.viz_enable_sandbox ? aws_iam_policy.write_read_access_viz_secrets_policy[0].arn : var.dockerhub_access_iam_policy_arn
}

data "aws_secretsmanager_secret" "dockerhub_creds" {
  arn = var.secret_dockerhub_arn
}