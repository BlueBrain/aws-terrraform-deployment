# Subnet for the KG Inference api
resource "aws_subnet" "kg_inference_api" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.7.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "kg_inference_api"
    SBO_Billing = "kg_inference_api"
  }
}

# Link route table to kg_inference_api network
resource "aws_route_table_association" "kg_inference_api" {
  subnet_id      = aws_subnet.kg_inference_api.id
  route_table_id = var.route_table_id
}

resource "aws_network_acl" "kg_inference_api" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.kg_inference_api.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 106
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 2049
    to_port    = 2049
  }
  tags = {
    Name        = "kg_inference_api_acl"
    SBO_Billing = "kg_inference_api"
  }
}