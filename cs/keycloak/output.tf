output "keycloak_lb_rule_suffix" {
  description = "KeyCloak Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.keycloak_target_group.arn_suffix
}