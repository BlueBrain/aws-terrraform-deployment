aws_region                 = "us-east-1"
obp_vpc_id                 = "vpc-06465039e2fbae370"
sbo_billing                = "hpc"
slurm_mysql_admin_username = "slurm_admin"
slurm_mysql_admin_password = "arn:aws:secretsmanager:us-east-1:130659266700:secret:slurmdb-7qMcsJ"
create_compute_instances   = true
num_compute_instances      = 0
compute_instance_type      = "m7g.medium"
create_slurmdb             = true
create_jumphost            = true
compute_nat_access         = false
compute_subnet_count       = 15
av_zone_suffixes           = ["a"]
# av_zone_suffixes       = ["a", "b", "c", "d"]
peering_route_tables   = ["rtb-0d570d1a815939248"]
existing_route_targets = ["172.31.0.0/16"]
account_id             = "130659266700"
lambda_subnet_cidr     = "172.31.2.0/24"
