resource "aws_vpc" "databricks" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "databricks"
    Terraform = "True"
  }
}

resource "aws_subnet" "subnet-NAT" {
  vpc_id     = aws_vpc.databricks.id
  cidr_block = "10.0.224.0/19"

  tags = {
    Name = "subnet-NAT"
  }
}

resource "aws_subnet" "subnet-A" {
  vpc_id     = aws_vpc.databricks.id
  cidr_block = "10.0.0.0/19"

  tags = {
    Name = "subnet-A"
  }
}

resource "aws_subnet" "subnet-B" {
  vpc_id     = aws_vpc.databricks.id
  cidr_block = "10.0.32.0/19"

  tags = {
    Name = "subnet-B"
  }
}

resource "aws_internet_gateway" "databricks-gw" {
  vpc_id = aws_vpc.databricks.id

  tags = {
    Name = "databricks-gw"
  }
}

resource "aws_eip" "databricks" {
  instance = aws_instance.databricks.id
  vpc      = true
}

resource "aws_nat_gateway" "databricks-ngw" {
  allocation_id = aws_eip.databricks.id
  subnet_id     = aws_subnet.subnet-NAT.id

  tags = {
    Name = "gw-NAT"
  }
}

resource "aws_route_table" "databricks-NAT" {
  vpc_id = aws_vpc.databricks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.databricks-gw.id
  }

  tags = {
    Name = "databricks-NAT"
  }
}

resource "aws_route_table_association" "route-table-association-NAT" {
  subnet_id      = aws_subnet.subnet-NAT.id
  route_table_id = aws_route_table.databricks-NAT.id
}

resource "aws_route_table" "databricks-private" {
  vpc_id = aws_vpc.databricks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.databricks-gw.id
  }

  tags = {
    Name = "databricks-private"
  }
}

resource "aws_route_table_association" "route-table-association-private-A" {
  subnet_id      = aws_subnet.subnet-A.id
  route_table_id = aws_route_table.databricks-private.id
}

resource "aws_route_table_association" "route-table-association-private-B" {
  subnet_id      = aws_subnet.subnet-B.id
  route_table_id = aws_route_table.databricks-private.id
}

resource "aws_network_acl" "databricks-acl" {
  vpc_id = aws_vpc.databricks.id
  subnet_ids = [aws_subnet.subnet-NAT.id, aws_subnet.subnet-A.id, aws_subnet.subnet-B.id]
}

resource "aws_network_acl_rule" "databricks-acl-rule-inbound" {
  network_acl_id = aws_network_acl.databricks-acl.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "databricks-acl-rule-outbound" {
  network_acl_id = aws_network_acl.databricks-acl.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_security_group" "databricks-sg" {
  name        = "databricks-sg"
  description = "databricks security group"
  vpc_id      = aws_vpc.databricks.id

  ingress {
    description = "Ingress TCP"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
  }

  ingress {
    description = "Ingress UDP"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "databricks-sg"
  }
}
