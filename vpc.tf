########################################
# Minimal VPC with public & private subnets
# Public → Internet via IGW
# Private → internal-only (no 0.0.0.0/0 route)
########################################

data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "this" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "kv-lab-vpc"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags = { Name = "kv-lab-igw" }
}

# ------------ Public subnets (2 AZs) ------------
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.10.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = { Name = "kv-lab-public-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.10.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = { Name = "kv-lab-public-b" }
}

# Route table for public subnets: 0.0.0.0/0 → IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "kv-lab-public-rt" }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ------------ Private subnets (2 AZs) ------------
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.10.10.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = { Name = "kv-lab-private-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.10.11.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = { Name = "kv-lab-private-b" }
}

# Route table for private subnets (no internet route)
# Local route 10.10.0.0/16 існує за замовчуванням, додаткові маршрути не додаємо.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "kv-lab-private-rt" }
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ------------ Outputs ------------
output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  description = "IDs of public subnets"
}

output "private_subnet_ids" {
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  description = "IDs of private subnets"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.igw.id
  description = "IGW ID for public subnets"
}

