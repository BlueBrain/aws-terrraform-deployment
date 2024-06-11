resource "aws_route53_record" "nexus_app_efs" {
  zone_id = var.domain_zone_id
  name    = "nexus-app-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.delta.efs_delta_dns_name]
}