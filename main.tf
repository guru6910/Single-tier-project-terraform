terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "guru"

}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "aws_vpc",
    } 
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "VM-1",
  }
}

resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/25"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true 

  tags = {
    Name = "VM-2",
  }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
      Name = "aws_internet_gateway_1"
    }
  
}

resource "aws_route_table" "RT1" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    
    }

}

resource "aws_route_table_association" "association" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.RT1.id
}


resource "aws_security_group" "sg1" {
  name = "single"
  description = "Allow SSH,mysql,tomcat access"
  vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

resource "aws_vpc_security_group_ingress_rule" "tomcat" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 8080
  ip_protocol = "tcp"
  to_port = 8080
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 80
  ip_protocol = "tcp"
  to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "mysql" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 3306
  ip_protocol = "tcp"
  to_port = 3306
  
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_network_interface" "network1" {
  subnet_id = aws_subnet.subnet-1.id
  private_ip = "10.0.1.100/24"
}

resource "aws_instance" "instance" {
  ami = "ami-08a0d1e16fc3f61ea"
  instance_type = "t2.micro"
  key_name = "terraform-key"
   network_interface {
    network_interface_id = aws_network_interface.network1.id
    device_index = 0
  }
   tags = {
    Name = "VM-1"
  }
}

resource "aws_network_interface_sg_attachment" "sg2" {
  security_group_id = aws_security_group.sg1.id
  network_interface_id = aws_instance.instance.primary_network_interface_id

}

resource "aws_db_subnet_group" "subnet-group" {
  name = "subnet-group"
  subnet_ids = [aws_subnet.subnet-1.id,aws_subnet.subnet-2.id]
  tags = {
    Name = "subnet-group"
  }
}
  
resource "aws_db_instance" "rds" {
  allocated_storage = 20
  db_name = "student"
  engine = "mariadb"
  engine_version = "10.11.6"
  username = "admin"
  password = "passwd123"
  instance_class = "db.t3.micro"
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.subnet-group.name
  vpc_security_group_ids = [aws_security_group.sg1.id]

  tags = {
    Name = "RDS"
  }
}
