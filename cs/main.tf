module "networking" {
  source         = "./networking"
  vpc_id         = var.vpc_id
  route_table_id = var.route_table_id
}

module "keycloak" {
  source              = "./keycloak"
  private_subnets     = module.networking.keycloak_private_subnets
  vpc_id              = var.vpc_id
  db_instance_class   = var.db_instance_class
  public_alb_listener = var.public_alb_listener

  preferred_hostname = "openbluebrain.com"
  redirect_hostnames = ["openbluebrain.ch", "openbrainplatform.org", "openbrainplatform.com"]

  keycloak_bucket_name = var.keycloak_bucket_name
  datasync_subnet_arn  = "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/subnet-03e6e9df2641a2e47"

  efs_mt_subnets = module.networking.keycloak_private_subnets

  allowed_source_ip_cidr_blocks = var.allowed_source_ip_cidr_blocks

  aws_region = var.aws_region
  account_id = var.account_id
}
