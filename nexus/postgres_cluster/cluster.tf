resource "aws_db_subnet_group" "nexus_cluster_subnet_group" {
  name       = "nexus-cluster-group"
  subnet_ids = var.subnets_ids
}

# TODO the secret should be defined in the code
# Data source to retrieve the password from AWS Secrets Manager
data "aws_secretsmanager_secret_version" "nexus_database_password" {
  secret_id = var.nexus_postgresql_database_password_arn
}

# tfsec:ignore:aws-rds-encrypt-cluster-storage-data
resource "aws_rds_cluster" "nexus" {
  cluster_identifier        = "nexus"
  availability_zones        = ["us-east-1a", "us-east-1b", "us-east-1c"]
  engine                    = "postgres"
  engine_version            = "15"
  db_cluster_instance_class = var.instance_class
  storage_type              = "io1"
  allocated_storage         = 100
  iops                      = 1000

  backup_retention_period = 7 # in days
  storage_encrypted       = false

  db_subnet_group_name   = aws_db_subnet_group.nexus_cluster_subnet_group.name
  vpc_security_group_ids = [var.security_group_id]

  master_username = var.nexus_postgresql_database_username
  master_password = data.aws_secretsmanager_secret_version.nexus_database_password.secret_string

  copy_tags_to_snapshot = true
}