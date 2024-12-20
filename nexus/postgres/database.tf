resource "aws_db_subnet_group" "nexus_db_subnet_group" {
  name       = "nexus-db-group"
  subnet_ids = var.subnets_ids
  tags = {
    SBO_Billing = "nexus"
    Nexus       = "postgres"
  }
}

# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "nexus_database_password" {
  secret_id = var.nexus_secrets_arn
}

# tfsec:ignore:aws-rds-enable-performance-insights-encryption
resource "aws_db_instance" "nexusdb" {
  #ts:skip=AC_AWS_0053
  #ts:skip=AC_AWS_0454
  #ts:skip=AC_AWS_0058
  deletion_protection     = false #tfsec:ignore:AVD-AWS-0177
  allocated_storage       = 40    # in gigabytes
  backup_retention_period = 7     # in days

  db_subnet_group_name = aws_db_subnet_group.nexus_db_subnet_group.name

  engine         = "postgres"
  engine_version = "15"
  multi_az       = false
  instance_class = var.instance_class

  identifier = var.database_identifier
  db_name    = var.nexus_postgresql_database_name

  username = var.nexus_postgresql_database_username
  password = jsondecode(data.aws_secretsmanager_secret_version.nexus_database_password.secret_string)["postgres_password"]

  publicly_accessible          = false
  performance_insights_enabled = true
  storage_encrypted            = false #tfsec:ignore:aws-rds-encrypt-instance-storage-data

  vpc_security_group_ids = [var.subnet_security_group_id]

  skip_final_snapshot                 = true
  iam_database_authentication_enabled = false

  copy_tags_to_snapshot = true
}
