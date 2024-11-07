# Blazegraph instance dedicated to Blazegraph views
module "blazegraph_obp_bg" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 10240
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms6g -Xmx6g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-bg"
  blazegraph_efs_name      = "blazegraph-obp-bg"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_region = var.aws_region
}

# Blazegraph instance dedicated to composite views
module "blazegraph_obp_composite" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_blazegraph_tags
  }

  blazegraph_cpu              = 4096
  blazegraph_memory           = 10240
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms6g -Xmx6g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-obp-composite"
  blazegraph_efs_name      = "blazegraph-obp-composite"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn

  aws_region = var.aws_region
}

module "elasticsearch_obp" {
  source = "./elasticcloud"

  aws_region               = var.aws_region
  elastic_vpc_endpoint_id  = module.networking.elastic_vpc_endpoint_id
  elastic_hosted_zone_name = module.networking.elastic_hosted_zone_name

  elasticsearch_version = "8.15.3"

  hot_node_size  = "4g"
  hot_node_count = 2

  deployment_name = "nexus-obp-elasticsearch"

  aws_tags = {
    Nexus       = "elastic",
    SBO_Billing = "nexus"
  }
}

module "nexus_delta_obp" {
  source = "./delta"

  providers = {
    aws = aws.nexus_delta_tags
  }

  subnet_id                = module.networking.subnet_id
  subnet_security_group_id = module.networking.main_subnet_sg_id

  domain_name = var.domain_name

  delta_cpu       = 4096
  delta_memory    = 10240
  delta_java_opts = "-Xss2m -Xms6g -Xmx6g"

  delta_instance_name        = "nexus-delta-obp"
  delta_docker_image_version = "1.11.0-M5"
  delta_efs_name             = "delta-obp"
  s3_bucket_arn              = aws_s3_bucket.nexus_obp.arn
  s3_bucket_name             = var.nexus_obp_bucket_name

  ecs_cluster_arn                          = aws_ecs_cluster.nexus.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus.arn
  ecs_task_execution_role_arn              = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn                        = aws_secretsmanager_secret.nexus_secrets.arn

  private_delta_target_group_arn = module.obp_delta_target_group_new.private_lb_target_group_arn
  dockerhub_credentials_arn      = module.iam.dockerhub_credentials_arn

  postgres_host        = module.postgres_cluster_obp.writer_endpoint
  postgres_reader_host = module.postgres_cluster_obp.reader_endpoint

  elasticsearch_endpoint = module.elasticsearch_obp.http_endpoint
  elastic_password_arn   = module.elasticsearch_obp.elastic_user_credentials_secret_arn

  blazegraph_endpoint           = module.blazegraph_obp_bg.http_endpoint
  blazegraph_composite_endpoint = module.blazegraph_obp_composite.http_endpoint

  delta_search_config_commit = "b44315f7e078e4d0ae34d6bd3a596197e5a2b325"
  delta_config_file          = "delta-obp.conf"

  aws_region = var.aws_region
}
