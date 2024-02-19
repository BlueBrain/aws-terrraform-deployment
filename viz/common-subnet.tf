resource "aws_subnet" "viz_public_a" {
  count                   = local.sandbox_resource_count
  vpc_id                  = data.aws_vpc.selected.id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.1.0/25"
  map_public_ip_on_launch = true

  tags = {
    Name        = "viz-public-with-nat"
    SBO_Billing = "viz"
  }
}

resource "aws_subnet" "viz_public_b" {
  count                   = local.sandbox_resource_count
  vpc_id                  = data.aws_vpc.selected.id
  availability_zone       = "${var.aws_region}b"
  cidr_block              = "10.0.1.128/25"
  map_public_ip_on_launch = true

  tags = {
    Name        = "viz-public-with-nat"
    SBO_Billing = "viz"
  }
}

resource "aws_route_table" "viz_public" {
  count  = local.sandbox_resource_count
  vpc_id = data.aws_vpc.selected.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig[0].id
  }
  tags = {
    Name        = "viz_route_public"
    SBO_Billing = "viz"
  }
}

resource "aws_route_table_association" "viz_public_a" {
  subnet_id      = aws_subnet.viz_public_a[0].id
  route_table_id = aws_route_table.viz_public[0].id
}

resource "aws_route_table_association" "viz_public_b" {
  subnet_id      = aws_subnet.viz_public_b[0].id
  route_table_id = aws_route_table.viz_public[0].id
}

