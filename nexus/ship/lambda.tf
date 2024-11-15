locals {
  nexus_launch_ship_name = "nexus_launch_ship_task"
}

data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_package.zip"

  depends_on = [random_string.r]
}

# This resource only exists to enforce the archive_file to be generated
# during the apply part. See
# https://github.com/hashicorp/terraform-provider-archive/issues/39#issuecomment-815021702
resource "random_string" "r" {
  length  = 16
  special = false
}

resource "aws_lambda_function" "launch_ship" {
  function_name    = local.nexus_launch_ship_name
  filename         = "${path.module}/lambda_package.zip"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  role             = aws_iam_role.nexus_ship_lambda.arn
  runtime          = "python3.12"
  architectures    = ["arm64"]
  handler          = "lambda_function.lambda_handler"
  timeout          = 10

  depends_on = [
    aws_iam_role_policy_attachment.run_ship_logging_role,
    aws_cloudwatch_log_group.launch_ship,
  ]

  tracing_config {
    mode = "Active"
  }
}

resource "aws_cloudwatch_log_group" "launch_ship" {
  name              = local.nexus_launch_ship_name
  skip_destroy      = false
  retention_in_days = 7
  kms_key_id        = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key
}