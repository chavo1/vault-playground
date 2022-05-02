resource "aws_vpc" "chavo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.environment_name}-vpc"
  }
}
# Create private subnets
resource "aws_subnet" "private" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.chavo_vpc.id
  map_public_ip_on_launch = false
  availability_zone       = "${var.availability_zones}"

  tags = {
    Name = "chavo-private"
  }
}
# Create public subnet
resource "aws_subnet" "public" {
  cidr_block              = "10.0.101.0/24"
  vpc_id                  = aws_vpc.chavo_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = "${var.availability_zones}"

  tags = {
    Name = "chavo-public"
  }
}
# Internet Gateway for the public subnet
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.chavo_vpc.id

  tags = {
    Name = "Internet Gateway for chavo_vpc"
  }
}
# Route to internet for private subnet traffic through the NatGW
resource "aws_route" "throug_internet_gw" {
  route_table_id         = aws_vpc.chavo_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id         = aws_internet_gateway.internet_gw.id
}
# Explicitly associate private subnet to the main
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_vpc.chavo_vpc.main_route_table_id
}
# Explicitly associate the newly created route tables to the public subnets (so they don't default to the main route table)
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
# Create a new route table for the public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.chavo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }
  tags = {
    Name = "chavo-route-public"
  }
}
