terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Configure the AWS Provider
provider "aws" {
  region = var.region
}


# We create a new VPC
resource  "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    name = var.vpc_name
  }
}


# We create three public subnets for three availability zones in our region (within the same VPC)

resource "aws_subnet" "public_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }
}


resource "aws_subnet" "public_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}

resource "aws_subnet" "public_subnet_3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.5.0/24"
  availability_zone = "eu-north-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_3"
  }
}


# We create three private subnets for three availability zones in our region (within the same VPC)

resource "aws_subnet" "private_subnet_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    name = "private_subnet_1"
  }
}


resource "aws_subnet" "private_subnet_2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = false

  tags = {
    name = "private_subnet_2"
  }
}

resource "aws_subnet" "private_subnet_3" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.6.0/24"
  availability_zone = "eu-north-1c"
  map_public_ip_on_launch = false

  tags = {
    name = "private_subnet_3"
  }
}


# Create an internet gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    name = "new_internet_gateway"
  }
}



# we need three NAT gateways (Best Practice) to be placed in the three public subnets. Each NAT gateway should have an elastic IP attached to it.


# NAT gateway1 and its elastic IP

resource "aws_eip" "nat_eip1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw1" {
  subnet_id = aws_subnet.public_subnet_1.id
  allocation_id = aws_eip.nat_eip1.id

  tags = {
    name = "private_nat_gw1"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


# NAT gateway2 and its elastic IP

resource "aws_eip" "nat_eip2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw2" {
  subnet_id = aws_subnet.public_subnet_2.id
  allocation_id = aws_eip.nat_eip2.id

  tags = {
    name = "private_nat_gw2"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}




# NAT gateway3 and its elastic IP

resource "aws_eip" "nat_eip3" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw3" {
  subnet_id = aws_subnet.public_subnet_3.id
  allocation_id = aws_eip.nat_eip3.id

  tags = {
    name = "private_nat_gw3"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}



# Create a route table for the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
    }

  tags = {
    name = "public_route_table"
  }
}



# Create three route tables for the private subnets and to each one, add a nat gateway.

resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw1.id
    }

  tags = {
    name = "private_route_table1"
  }

}



resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw2.id
    }

  tags = {
    name = "private_route_table2"
  }

}



resource "aws_route_table" "private_route_table3" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw3.id
    }

  tags = {
    name = "private_route_table3"
  }

}



# Associate the public route table to the 3 public subnets in the three availability zones

resource "aws_route_table_association" "public_assoc1" {
  subnet_id = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}


resource "aws_route_table_association" "public_assoc2" {
  subnet_id = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_assoc3" {
  subnet_id = aws_subnet.public_subnet_3.id
  route_table_id = aws_route_table.public_route_table.id
}



# Associate the three private route tables to the 3 private subnets in the three availability zones

resource "aws_route_table_association" "private_assoc1" {
  subnet_id = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table1.id
}


resource "aws_route_table_association" "private_assoc2" {
  subnet_id = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table2.id
}


resource "aws_route_table_association" "private_assoc3" {
  subnet_id = aws_subnet.private_subnet_3.id
  route_table_id = aws_route_table.private_route_table3.id
}



# Outputs

output "main_vpc_id" {
  value = aws_vpc.main.id
}


output "public_subnet1_id" {
  value = aws_subnet.public_subnet_1.id
}


output "public_subnet2_id" {
  value = aws_subnet.public_subnet_2.id
}


output "public_subnet3_id" {
  value = aws_subnet.public_subnet_3.id
}


output "private_subnet1_ids" {
  value = aws_subnet.private_subnet_1.id
}


output "private_subnet2_ids" {
  value = aws_subnet.private_subnet_2.id
}


output "private_subnet3_ids" {
  value = aws_subnet.private_subnet_3.id
}