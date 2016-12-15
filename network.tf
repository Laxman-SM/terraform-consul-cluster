//  Setup the core provider information.
provider "aws" {
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}

//  Define the VPC.
resource "aws_vpc" "consul-cluster" {
  cidr_block = "10.0.0.0/16" // i.e. 10.0.0.0 to 10.0.255.255
  enable_dns_hostnames = true
  tags { 
    Name = "Consul Cluster VPC" 
    Project = "consul-cluster"
  }
}

//  Create an Internet Gateway for the VPC.
resource "aws_internet_gateway" "consul-cluster" {
  vpc_id = "${aws_vpc.consul-cluster.id}"
  tags {
    Name = "Consul Cluster IGW"
    Project = "consul-cluster"
  }
}

//  Create a public subnet for each AZ.
resource "aws_subnet" "public-a" {
  vpc_id            = "${aws_vpc.consul-cluster.id}"
  cidr_block        = "10.0.1.0/24" // i.e. 10.0.1.0 to 10.0.1.255
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.consul-cluster"]
  tags { 
    Name = "Consul Cluster Public Subnet" 
    Project = "consul-cluster"
  }
}
resource "aws_subnet" "public-b" {
  vpc_id            = "${aws_vpc.consul-cluster.id}"
  cidr_block        = "10.0.2.0/24" // i.e. 10.0.2.0 to 10.0.1.255
  availability_zone = "ap-southeast-1b"
  map_public_ip_on_launch = true
  depends_on = ["aws_internet_gateway.consul-cluster"]
  tags { 
    Name = "Consul Cluster Public Subnet" 
    Project = "consul-cluster"
  }
}

//  Create a route table allowing all addresses access to the IGW.
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.consul-cluster.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.consul-cluster.id}"
  }
  tags {
    Name = "Consul Cluster Public Route Table"
    Project = "consul-cluster"
  }
}

//  Now associate the route table with the public subnet - giving
//  all public subnet instances access to the internet.
resource "aws_route_table_association" "public-a" {
  subnet_id = "${aws_subnet.public-a.id}"
  route_table_id = "${aws_route_table.public.id}"
}
resource "aws_route_table_association" "public-b" {
  subnet_id = "${aws_subnet.public-b.id}"
  route_table_id = "${aws_route_table.public.id}"
}

//  Create an internal security group for the VPC, which allows everything in the VPC
//  to talk to everything else.
resource "aws_security_group" "consul-cluster-vpc" {
  name = "consul-vpc"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
  vpc_id = "${aws_vpc.consul-cluster.id}"

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = true
  }

  tags { 
    Name = "Consul Cluster Internal VPC" 
    Project = "consul-cluster"
  }
}

//  Create a security group allowing web access to the public subnet.
resource "aws_security_group" "web" {
  name = "web"
  description = "Security group for web that allows web traffic from internet"
  vpc_id = "${aws_vpc.consul-cluster.id}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags { 
    Name = "Consul Cluster VPC Web" 
    Project = "consul-cluster"
  }
}