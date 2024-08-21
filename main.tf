###################################################################
# Define Terraform State storage 
terraform {
  backend "s3" {
    bucket                  = "jw75-terraform-s3-state"
    key                     = "TestVPC"
    region                  = "us-east-2"
    shared_credentials_file = "~/.aws/credentials"
  }
}

###################################################################
# VPC
resource "aws_vpc" "TestVPC" {
  cidr_block = var.cidr_block
}

# VPC Subnets
resource "aws_subnet" "TestVPC_Subnet2a" {
  vpc_id            = aws_vpc.TestVPC.id
  cidr_block        = "172.16.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "TestVPC_Subnet2a"
  }
}

###################################################################
# Internet Gateway
resource "aws_internet_gateway" "TestVPC_IGW" {
  vpc_id = aws_vpc.TestVPC.id
  tags = {
    name = "TestVPC_IGW"
  }
}

###################################################################
# Route Table
resource "aws_route_table" "TestVPC_RTB" {
  vpc_id = aws_vpc.TestVPC.id
  tags = {
    name = "TestVPC_RTB"
  }
}
# Default Route
resource "aws_route" "TestVPC_RT" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id  = aws_internet_gateway.TestVPC_IGW.id
  route_table_id = aws_route_table.TestVPC_RTB.id
}

###################################################################
# IGW Association
resource "aws_route_table_association" "TestVPC_RTB_assoc" {
  subnet_id = aws_subnet.TestVPC_Subnet2a.id
  route_table_id = aws_route_table.TestVPC_RTB.id
}

###################################################################
# Web Security Group
resource "aws_security_group" "TestVPC_web_sg" {
  name        = "web_sg"
  description = "Web tier SG"
  vpc_id      = aws_vpc.TestVPC.id

  tags = {
    Name = "TestVPC_web_sg"
  }
}
# Security Group Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "http_ipv4" {
  security_group_id = aws_security_group.TestVPC_web_sg.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "151.197.233.121/32"
}

# Security Group Egress Rule
resource "aws_vpc_security_group_egress_rule" "outbound_all_traffic_ipv4" {
  security_group_id = aws_security_group.TestVPC_web_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

###################################################################
# Management Security Group
resource "aws_security_group" "TestVPC_mgmt_sg" {
  name        = "mgmt_sg"
  description = "Management SG"
  vpc_id      = aws_vpc.TestVPC.id

  tags = {
    Name = "TestVPC_mgmt_sg"
  }
}
# Security Group Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "mgmt_ipv4" {
  security_group_id = aws_security_group.TestVPC_mgmt_sg.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "151.197.233.121/32"
}

###################################################################
# Define Network Interfaces
resource "aws_network_interface" "TestVPC_web_net_interface" {
  subnet_id                 = aws_subnet.TestVPC_Subnet2a.id
  security_groups           = [aws_security_group.TestVPC_web_sg.id, aws_security_group.TestVPC_mgmt_sg.id]
}

resource "aws_eip" "TestVPC_web_eip" {
  network_interface         = aws_network_interface.TestVPC_web_net_interface.id
  associate_with_private_ip = aws_network_interface.TestVPC_web_net_interface.private_ip
  depends_on                = [aws_internet_gateway.TestVPC_IGW]
}

###################################################################
# Define OS, Architecture and Version
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"] #canonical
}

###################################################################
# Create Instances and deploy application
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = "TestVPC_key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.TestVPC_web_net_interface.id
  }

  user_data = file("${path.module}/user_data.sh")
 
  tags = {
    name = "web_server"
  }
}
