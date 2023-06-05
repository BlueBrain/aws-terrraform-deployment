# Created in AWS secret manager
variable "sbo_nexus_app_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:nexus_app-xfJP5F"
  type        = string
  description = "The ARN of the SBO nexus app secrets"
  sensitive   = true
}

resource "aws_iam_policy" "sbo_nexus_app_secrets_access" {
  name        = "sbo-nexus-app-secrets-access-policy"
  description = "Policy that gives access to the SBO nexus app secrets"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "${var.sbo_nexus_app_secrets_arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "nexus_app"
  }
}