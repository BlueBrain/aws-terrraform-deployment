# TODO - the 'backend' was generated by Terragrunt using the 'remote_state' below.
# This automatically creates the bucket and dynamodb table.
# When we can run commands in nexus root, the state can be overwritten.
# 
# remote_state {
#   backend = "s3"
#   generate = {
#     path      = "backend.tf"
#     if_exists = "overwrite"
#   }
#   config = {
#     bucket         = "nexus-sandbox-tfstate"
#     dynamodb_table = "nexus-sandbox-tfstate-lock-table"
#     encrypt        = true
#     key            = "./terraform.tfstate"
#     region         = "us-east-1"
#   }
# }
# 
# terraform {
#   backend "s3" {
#     bucket         = "nexus-sandbox-tfstate"
#     dynamodb_table = "nexus-sandbox-tfstate-lock-table"
#     encrypt        = true
#     key            = "./terraform.tfstate"
#     region         = "us-east-1"
#   }
# }