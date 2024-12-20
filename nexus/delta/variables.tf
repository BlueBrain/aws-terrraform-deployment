variable "subnet_id" {
  type        = string
  description = "ID of the subnet in which Delta should run"
}

variable "delta_instance_name" {
  type        = string
  description = "Unique name to use to parametrize the different components in this module. This allows to instantiate the module several times without collisions, allowing for instance for a parallel deployment of Delta."
}

variable "delta_cpu" {
  type        = number
  description = "vCPU value for the Delta task"
}

variable "delta_memory" {
  type        = number
  description = "RAM value for the Delta task"
}

variable "delta_java_opts" {
  type        = string
  description = "JAVA_OPTS for the Delta task"
}

variable "desired_count" {
  type        = number
  description = "Number of tasks that the service should run. Set to 0 to not run anything."
  default     = 1
}

variable "delta_efs_name" {
  type        = string
  description = "Unique name for the EFS associated with Delta. This is where the Delta config and the search config are stored and later mounted to the container."
}

variable "delta_config_file" {
  type        = string
  description = "The filename of the config delta should use. This is only needed if there are two deployments of delta contained within this terraform."
}

variable "delta_docker_image_version" {
  type        = string
  description = "Version of the Delta Docker image."
}

variable "s3_bucket_arn" {
  type        = string
  description = "ARN of the S3 Bucket that Delta will use for S3 Storage."
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 Bucket that Delta will use for S3 Storage."
}

variable "postgres_host" {
  type        = string
  description = "Address of the postgres instance delta should use; specified using the $POSTGRES_PASSWORD variable in the delta config"
}

variable "postgres_reader_host" {
  type        = string
  description = "Address of the postgres reader pool for delta; specified using the $POSTGRES_READER_ENDPOINT variable in the delta config. If the config does not use it, then this terraform variable can a blank string."
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "Endpoint of the elasticsearch instance Delta should use."
}

variable "subnet_security_group_id" {
  type        = string
  description = "Security group applied to the resource which should describe how the resource can communicate inside the subnet."
}

variable "ecs_cluster_arn" {
  type        = string
  description = "ARN of the ECS Cluster in which Delta should run."
}

variable "aws_service_discovery_http_namespace_arn" {
  type        = string
  description = "The ARN of the ECS Service Discover namespace in which the Delta task will be included. This is so that Delta can call Blazegraph without the use of a load balancer; Blazegraph needs to be in the same namespace."
}

variable "ecs_task_execution_role_arn" {
  type        = string
  description = "The ARN of the ECS task execution role that is used by the ECS agent."
}

variable "nexus_secrets_arn" {
  type        = string
  description = "The ARN of the secrets manager secret that contains the nexus secrets."
}

variable "elastic_password_arn" {
  type        = string
  description = "ARN of the secret that contains the elastic user password. The password needs to be under the 'password' key."
}

variable "private_delta_target_group_arn" {
  type        = string
  description = "ARN of the private ALB target group that the ECS Service will be targeted by."
}

variable "delta_search_config_commit" {
  type        = string
  description = "The github commit hash (or tag/branch) of nexus that contains the search config which should be used in this deployment"
}

variable "dockerhub_credentials_arn" {
  type        = string
  description = "ARN of the secret that contains valid Dockerhub credentials to pull docker images while authenticated."
}

# Blazegraph specific
variable "blazegraph_endpoint" {
  type        = string
  description = "Endpoint of the blazegraph instance delta should use. This is parametrized as $BLAZEGRAPH_ENDPOINT in the configuration."
}

variable "blazegraph_composite_endpoint" {
  type        = string
  description = "Endpoint of the blazegraph instance delta should use for the composite views; unused if the delta config does not use the $BLAZEGRAPH_COMPOSITE_ENDPOINT. Leave a blank string if this is not necessary."
}

variable "domain_name" {
  type = string
}
