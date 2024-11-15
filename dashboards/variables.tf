variable "aws_region" {
  type = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "private_load_balancer_target_suffixes" {
  type = map(string)
}

variable "private_load_balancer_id" {
  type = string
}
