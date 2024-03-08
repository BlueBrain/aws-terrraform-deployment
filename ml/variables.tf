# Locals
locals {
  ecs_cluster_arn    = module.ml_ecs_cluster.arn
  private_subnet_ids = [aws_subnet.ml_subnet_a.id, aws_subnet.ml_subnet_b.id]
}

# Variables
variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "account_id" {
  description = "AWS account id."
  type        = string
  default     = "671250183987"

}
variable "vpc_id" {
  description = "ID of the vpc"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "route_table_private_subnets_id" {
  description = "ID of the route table for the private subnets"
}

variable "alb_listener_arn" {
  description = "ARN of the Load Balancer Listener"
  type        = string
}

variable "private_alb_listener_arn" {
  description = "ARN of the Load Balancer Listener on Private subnets."
  type        = string
}

variable "backend_image_url" {
  description = "Url of the ECR image to use in the ECS image (format repo:tag)"
  type        = string
}

variable "etl_image_url" {
  description = "Url of the ECR image to use in the ECS image (format repo:tag)"
  type        = string
}

variable "dockerhub_credentials_arn" {
  description = "arn of the credentials to the dockerhub instance."
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the security group attached to the public load balancer."
  type        = string
}

variable "private_alb_security_group_id" {
  description = "ID of the security group attached to the private load balancer."
  type        = string
}

variable "secret_manager_arn" {
  description = "ARN of the secret manager"
}

variable "os_domain_name" {
  description = "Name of the OS instance"
  type        = string
  default     = "ml-os"

}

variable "os_version" {
  description = "Version of the Opensearch cluster"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "os_node_number" {
  description = "Number of nodes of the Opensearch cluster."
  type        = number
  default     = 1
}

variable "os_instance_type" {
  description = "Type of opensearch instance"
  type        = string
  default     = "t3.medium.search"
}

variable "os_ebs_volume" {
  description = "Storage size per node. Depends on the instance type"
  type        = number
  default     = 200
}

variable "os_ebs_throughput" {
  description = "Trhoughput of the gp3 ebs volume."
  type        = number
  default     = 255
}

variable "rds_engine" {
  description = "type of rds database."
  default     = "postgres"
}

variable "rds_version" {
  description = "version of the rds database."
  default     = "16.1"
}

variable "rds_instance_class" {
  description = "The instance class to use for the RDS instance."
  default     = "db.t4g.small"
}

variable "rds_allocated_storage" {
  description = "The amount of storage to allocate for the RDS instance (in gigabytes)."
  type        = number
  default     = 20
}

variable "rds_user" {
  description = "Unsername of the rds instance."
  default     = "postgres"
}

variable "rds_port" {
  description = "Port of the rds instance."
  type        = string
  default     = "5432"
}

variable "rds_param_group" {
  description = "Group of parameters for the rds instance."
  default     = "postgres14"
}

variable "ec_cluster_name" {
  description = "Name of the redis instance."
  default     = "redis-cluster"
}

variable "ec_engine" {
  description = "Engine of the cluster."
  default     = "redis"
}

variable "ec_node_type" {
  description = "Type of nodes for compute."
  default     = "cache.t4g.micro"
}

variable "ec_num_nodes" {
  default = 1
}

variable "ec_param_group" {
  description = "Group of parameters for redis"
  default     = "default.redis7"
}

variable "airflow_version" {
  description = "Version of the mwaa instance."
  default     = "2.8.1"
}

variable "airflow_instance_type" {
  description = "Type of airflow instance."
  default     = "mw1.small"
}

variable "airflow_min_worker" {
  description = "Minimum number of workers."
  type        = number
  default     = 1
}

variable "airflow_max_worker" {
  description = "Maximum number of workers."
  type        = number
  default     = 1
}