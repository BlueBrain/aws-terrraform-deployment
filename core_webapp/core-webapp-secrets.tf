#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "core_webapp_secrets" {
  name        = "core_webapp_secrets"
  description = "Core webapp secrets"
}

resource "aws_iam_policy" "sbo_core_webapp_secrets_access" {
  name        = "sbo-core-webapp-secrets-access-policy"
  description = "Policy that gives access to the SBO core webapp secrets"

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
        "${aws_secretsmanager_secret.core_webapp_secrets.arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "core_webapp"
  }
}
