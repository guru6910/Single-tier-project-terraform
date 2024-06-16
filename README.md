# ${\color{red} \textbf{Project : Single-tier terraform}}$

**create profile with access key and secret key**
````
aws configure --profile <profile name>
````
**add provider**
````
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
````
````
terraform init
````
**create a vpc**
````
resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        Name = "aws_vpc",
    } 
}
````
**create a public subnet**
````
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true 

  tags = {
    Name = "VM-1",
  }
}
````
**create a internet Gateway**
````
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
      Name = "aws_internet_gateway_1"
    }
  
}
````
**create a public route table**
````
resource "aws_route_table" "RT1" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    
    }

}
````
**add public subnet public route association**
````
resource "aws_route_table_association" "association" {
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.RT1.id
}
````
**create a security group**
````
resource "aws_security_group" "sg1" {
  name = "single"
  description = "Allow SSH,mysql,tomcat access"
  vpc_id = aws_vpc.vpc.id
}
````
**Add port 22,80,8080,3306 in inbound rule**
````
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
````
**add outbount rule**
````
resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.sg1.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}
````
**create a key pair from GUI and use that key name when we creat a instance**

**Add network interface with public subnet to connet to public instance**
````
resource "aws_network_interface" "network1" {
  subnet_id = aws_subnet.subnet-1.id
  private_ip = "10.0.1.100/24"
}
````
**Create a instance**
````
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
````
**Attach the security group to instance**
````
resource "aws_network_interface_sg_attachment" "sg2" {
  security_group_id = aws_security_group.sg1.id
  network_interface_id = aws_instance.instance.primary_network_interface_id
}
````
````
terraform plan
````
````
terraform apply -auto-approve
````
**Create a file with the name of terraform-key.pem and add a key content which key we assigned with instances**
````
vim terraform-key.pem
````
**give 600 permission to file**
````
chmod 600 terraform-key.pem
````
## ${\color{red} \textbf{Connect to Server}}$

**install java**
````
yum install java -y
````
**install binary package of apache-tomcat with zip link from its website**
````
curl -O https://dlcdn.apache.org/tomcat/tomcat-8/v8.5.100/bin/apache-tomcat-8.5.100.zip
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/4ae1ac24-b711-4c21-af65-ceb757646fdc)

**extract the file with unzip**
````
unzip apache-tomcat-8.5.100.zip
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/50af9db0-488a-477f-8fab-b82ba73b37bf)

````
cd apache-tomcat-8.5.100
````
````
cd webapps
````
**install student.war file**
````
curl -O https://s3-us-west-2.amazonaws.com/studentapi-cit/student.war
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/376d328a-bc02-47ce-8fe7-c03e6638eb65)

````
cd ../lib
````
**install mysql connector jar file**
````
curl -O https://s3-us-west-2.amazonaws.com/studentapi-cit/mysql-connector.jar
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/4a221477-aa57-4659-b5c3-5b4644110105)

