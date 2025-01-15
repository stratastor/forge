terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# 1. Create VPC
resource "aws_vpc" "staging-vpc" {
  cidr_block = var.aws_vpc_cidr_block
  tags = {
    Name = "Staging VPC"
  }
}

# 2. Create an Internet Gateway in the VPC, so we can actually send traffic out ot the internet
resource "aws_internet_gateway" "staging-gateway" {
  vpc_id = aws_vpc.staging-vpc.id
}

# 3. Create a custom route table
resource "aws_route_table" "staging-route-table" {
  vpc_id = aws_vpc.staging-vpc.id

  route {
    # The route is 0.0.0.0/0, it means it will send ALL internet traffic to this route
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.staging-gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.staging-gateway.id
  }

  tags = {
    Name = "Staging Route Table"
  }
}

# 4. Create a subnet
resource "aws_subnet" "staging-subnet" {
  vpc_id     = aws_vpc.staging-vpc.id
  cidr_block = var.aws_subnet_cidr_block
  availability_zone = var.aws_availability_zone
  tags = {
    Name = "Staging Subnet"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "staging-route-table-association" {
  subnet_id      = aws_subnet.staging-subnet.id
  route_table_id = aws_route_table.staging-route-table.id
}

# 6. Create a security group to allow port 22(ssh) for webserver traffic
resource "aws_security_group" "staging-security-group" {
  name        = "Security Group"
  vpc_id      = aws_vpc.staging-vpc.id

  # For SSH
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" #ANY PROTOCOL
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Staging security group"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "staging-nic" {
  subnet_id       = aws_subnet.staging-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.staging-security-group.id]
}

# 8. Assign an elastic IP (a public IO thats routable through the internet) to the network interface we created in step 7
# An elastic IP needs an internet gateway to be deployed first before the eip gets deployed
# It must be associated with the EC2 AFTER it's in the running state
resource "aws_eip" "staging-eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.staging-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.staging-gateway, aws_instance.staging-environment ] #Makes sure this is created AFTER the Internet gateway
}

resource "aws_instance" "staging-environment" {
  ami                     = var.aws_ami
  availability_zone       = var.aws_availability_zone #It's preferred that the availability zone is the same as your subnet  
  instance_type           = var.aws_instance_type
  key_name                = var.aws_key_name

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.staging-nic.id
  }

# sudo cat /var/log/cloud-init-output.log
# git clone https://github.com/stratastor/rodent.git
# cd rodent/pkg/zfs/dataset/ && sudo go test -v -run TestDatasetOperations
  user_data = <<-EOF
    #!/bin/bash
    set -e
    apt-get update && apt-get upgrade -y

    # Install necessary tools
    apt-get install -y curl wget ssh git tar gcc g++ make python3 python3-dev uuid-dev libblkid-dev libtirpc-dev libssl-dev caddy samba jq nfs-kernel-server acl

    # Install Go(using snap)
    snap install go --classic

    # Start NFS server
    systemctl start nfs-kernel-server.service

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    # ZFS installation
    wget https://github.com/openzfs/zfs/releases/download/zfs-2.3.0-rc5/zfs-2.3.0-rc5.tar.gz
    tar -xvf zfs-2.3.0-rc5.tar.gz
    cd zfs-2.3.0-rc5
    ./configure
    make
    make install

    # Since we downloaded ZFS from source, the manual installation doesn't automatically update the dynamic linker configuration
    # We also need to load the kernel module manually

    echo "/usr/local/lib" | tee -a /etc/ld.so.conf.d/zfs.conf
    ldconfig
    modprobe zfs
    update-initramfs -u
  
    EOF


  tags = {
    Name="Staging Environment"
  }
}