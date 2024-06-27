resource "aws_lb_target_group" "virtual_lab_manager" {
  #ts:skip=AC_AWS_0492
  name        = "virtual-lab-manager"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled  = true
    path     = "${var.virtual_lab_manager_base_path}/health"
    protocol = "HTTP"
  }

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

data "aws_nat_gateway" "nat_gateway" {
  id = data.terraform_remote_state.common.outputs.nat_gateway_id
}

resource "aws_lb_listener_rule" "virtual_lab_manager" {
  listener_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  priority     = 203

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.virtual_lab_manager.arn
  }

  condition {
    path_pattern {
      values = ["${var.virtual_lab_manager_base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr, var.bbp_dmz_cidr, format("%s/32", data.aws_nat_gateway.nat_gateway.public_ip)]
    }
  }

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}
