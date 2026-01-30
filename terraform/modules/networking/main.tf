# modules/networking/main.tf

resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project_name}-vpc" }
}

resource "aws_subnet" "lab_subnet" {
  vpc_id                  = aws_vpc.lab_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
  tags = { Name = "${var.project_name}-subnet" }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lab_vpc.id
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.lab_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.lab_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "lab_sg" {
  name   = "${var.project_name}-sg"
  vpc_id = aws_vpc.lab_vpc.id

  # Allow SSH from User (Variables)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  # Allow HTTP/HTTPS/MySQL from outside (Optional)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Allow Internal Traffic (All Protocols) for Lab connectivity
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- DHCP Options for Search Domain (hyfertechsolutions.com) ---
resource "aws_vpc_dhcp_options" "lab_dhcp" {
  domain_name         = "hyfertechsolutions.com"
  domain_name_servers = ["AmazonProvidedDNS"]
  tags = { Name = "${var.project_name}-dhcp" }
}

resource "aws_vpc_dhcp_options_association" "lab_dns_resolver" {
  vpc_id          = aws_vpc.lab_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.lab_dhcp.id
}