
# Target Group definition
resource "aws_lb_target_group" "thumbnail_generation_api_private_tg" {
  name        = "thumbnail-gen-api-tg-private"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    enabled  = true
    path     = "${var.thumbnail_generation_api_base_path}/docs"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_lb_listener_rule" "thumbnail_generation_api_private" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.thumbnail_generation_api_private_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.thumbnail_generation_api_base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }

  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}
