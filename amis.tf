# AMI for AlmaLinux 9
data "aws_ami" "almalinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["AlmaLinux OS 9*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["764336703387"] # AlmaLinux
}

# AMI for latest Amazon Linux
data "aws_ami" "amazonlinux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*hvm*x86_64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

# Test image with nginx
data "aws_ami" "bitnami-nginx" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-nginx-*-linux-debian-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}