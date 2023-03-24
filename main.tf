resource "aws_vpc" "ipv6_vpc" {
  cidr_block       = var.cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = "ipv6_vpc"

  }
}
locals {
  ipv4_cidrs = cidrsubnets(aws_vpc.ipv6_vpc.cidr_block, 4, 4, 4, 2, 2, 2)
  ipv6_cidrs = cidrsubnets(aws_vpc.ipv6_vpc.cidr_block, 4, 4, 4, 2, 2, 2)

}


#Create 3 Public Subnets in each AZ
resource "aws_subnet" "public_ipv6_subnets" {
  vpc_id     = aws_vpc.ipv6_vpc.id
  count = length(var.pubsubnets)
  publicsubnet = var.pubsubnets[count.index]
  cidr_block = var.pubsubnets
  availability_zone = "${var.aws_region}${var.azs[count.index]}"

  ipv6_cidr_block = "${local.ipv6_cidrs}"
  ipv4_cidr_block = "${local.ipv4_cidrs}"
  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch = true

  tags = {
    Name = "public_ipv6_subnets"
  }
}
#create 3 private subnets in each AZ
resource "aws_subnet" "private_ipv6_subnets" {
  vpc_id     = aws_vpc.ipv6_vpc.id
  count = length(var.privsubnets)
  privatesubnet = var.privsubnets[count.index]
  ipv6_cidr_block = "${local.ipv6_cidrs}"
  ipv4_cidr_block = "${local.ipv4_cidrs}"
  cidr_block = var.privsubnets
  availability_zone = "${var.aws_region}${var.azs[count.index]}"



  assign_ipv6_address_on_creation = true
  map_public_ip_on_launch = true

  tags = {
    Name = "public_ipv6_subnets"
  }
}


#Create the Internet Gateway
resource "aws_internet_gateway" "ipv6_vpc_igw" {
  vpc_id = aws_vpc.ipv6_vpc.id

  tags = {
    Name = "ipv6_vpc_igw"
  }
}

#Create the Route Table
resource "aws_route_table" "ipv6_public_rt" {
  vpc_id = aws_vpc.ipv6_vpc.id

  #Set the default IPv4 route to use the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ipv6_vpc_igw.id
  }

  #Set the default IPv6 route to use the Internet Gateway
  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.ipv6_vpc_igw.id
  }

  tags = {
    Name = "ipv6_public_rt"
  }
}

#Associate the route with Public Subnet
resource "aws_route_table_association" "ipv6_ra_public" {
  count = length(var.pubsubnets)
  publicsubnet = var.pubsubnets[count.index]
  route_table_id = aws_route_table.ipv6_public_rt.id
}



#Create 3 NAT Gateways for the Private Subnet instaces
#Create EIP for each Gateway
resource "aws_eip" "nat_gateway_1" {
  vpc = true
}


#Create the 3 Gateways and place them in each public subnet
resource "aws_nat_gateway" "ipv6_nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id = aws_subnet.public_ipv6_subnet_1.id
  tags = {
    "Name" = "ipv6_nat_gateway_1"
  }
}


#Create a route table for the 3 private subnets and make the defauly route the nat gateway
resource "aws_route_table" "ipv6_private_rt_1" {
  vpc_id = aws_vpc.ipv6_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ipv6_nat_gateway_1.id
  }
  tags = {
    Name = "ipv6_private_rt_1"
  }
}




#Associate the route table to each private subnet
resource "aws_route_table_association" "ipv6_ra_private_1" {
  count = length(var.privsubnets)
  privatesubnet = var.privsubnets[count.index]
  route_table_id = aws_route_table.ipv6_private_rt_1.id
}

#IPv4 and IPv6 Security Group for Auto Scale Group
#Allow Traffic in from Public Subnet and all traffic out
resource "aws_security_group" "ipv6_allow_sg" {
  name        = "ipv6_allow_sg"
  description = "Allow connections from public subnet"
  vpc_id      = aws_vpc.ipv6_vpc.id

  #Allow HTTP Traffic from anywhere for IPv4
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow All Traffic from the VPC CIDR for IPv4
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  #Allow all traffic out
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
}