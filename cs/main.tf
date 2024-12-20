module "networking" {
  source                         = "./networking"
  vpc_id                         = var.vpc_id
  route_table_private_subnets_id = var.route_table_private_subnets_id
  aws_region                     = var.aws_region
}

module "keycloak" {
  source                         = "./keycloak"
  private_subnets                = module.networking.keycloak_private_subnets
  vpc_id                         = var.vpc_id
  db_instance_class              = var.db_instance_class
  private_alb_https_listener_arn = var.private_alb_https_listener_arn

  preferred_hostname = var.preferred_hostname
  redirect_hostnames = var.redirect_hostnames

  efs_mt_subnets = module.networking.keycloak_private_subnets

  keycloak_secrets_arn = var.keycloak_secrets_arn

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks

  aws_region = var.aws_region
  account_id = var.account_id
}
