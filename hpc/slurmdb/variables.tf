variable "slurm_mysql_admin_username" {
  type = string
}

variable "slurm_db_subnets_ids" {
  type = list(string)
}

variable "slurm_db_sg_id" {
  type = string
}

variable "create_slurmdb" {
  type = bool
}

variable "hpc_slurm_secrets_arn" {
  type = string
}
