resource "aws_ssoadmin_permission_set" "write_read_access_nexus_secrets" {
  name             = "WriteReadNexusSecrets"
  description      = "Write and Read access for Nexus secrets"
  instance_arn     = tolist(var.aws_ssoadmin_instances_arns)[0]
  session_duration = "PT2H"
  count            = var.is_production ? 1 : 0
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "write_read_access_nexus_secrets_inline_policy" {
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      jsondecode(local.write_read_access_nexus_secrets_policy),
      jsondecode(var.readonly_access_policy_statement_part1),
      jsondecode(var.readonly_access_policy_statement_part2),
    ]
  })
  instance_arn       = tolist(var.aws_ssoadmin_instances_arns)[0]
  permission_set_arn = aws_ssoadmin_permission_set.write_read_access_nexus_secrets[0].arn
  count              = var.is_production ? 1 : 0
}

locals {
  write_read_access_nexus_secrets_policy = jsonencode({
    Effect = "Allow"
    Action = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecret"
    ],
    "Resource" : [
      "arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:nexus*",
    ]
  })
}
