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
**create a second subnet it helps when we create a subnet group for rds**
````
resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/25"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true 

  tags = {
    Name = "VM-2",
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
**Create a subnet Group for DB**
````
resource "aws_db_subnet_group" "subnet-group" {
  name = "subnet-group"
  subnet_ids = [aws_subnet.subnet-1.id,aws_subnet.subnet-2.id]
  tags = {
    Name = "subnet-group"
  }
}
````
**Create A database for instance**
````
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

**install mariadb and start**
````
yum install mariadb105-server -y
systemctl start mariadb.server
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/51269f19-884a-4a88-979b-c534b9508ce9)

### ${\color{green} \textbf{log in database}}$

````
mysql -h <endpoint of database> -u <uname> -p<password>
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/0329cdf3-e01a-4e3e-84ea-52dd3a82b8d6)

````
create database studentapp;
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/01d7c51d-f46d-4ce6-908f-daca100b2429)

````
use studentapp;
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/244218d0-6623-43bc-acda-ccd9554ece32)

### ${\color{blue} \textbf{Create Table in DB}}$
````
 CREATE TABLE if not exists students(student_id INT NOT NULL AUTO_INCREMENT,  
	student_name VARCHAR(100) NOT NULL,  
	student_addr VARCHAR(100) NOT NULL,   
	student_age VARCHAR(3) NOT NULL,      
	student_qual VARCHAR(20) NOT NULL,     
	student_percent VARCHAR(10) NOT NULL,   
	student_year_passed VARCHAR(10) NOT NULL,  
	PRIMARY KEY (student_id)  
);
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/d3ee794e-9b97-402a-b452-13e3056bc655)


````
show tables;
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/48400c3d-29c1-4dd0-ab9c-4ff3e0fe0201)

````
describe students;
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/6de983e2-f2d2-4813-a04d-11c862c30eca)

````
exit
````
### ${\color{green} \textbf{log out database instance}}$

## ${\color{red} \textbf{Setup of Apache-Tomcat}}$
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

### ${\color{blue} \textbf{Modify Apache Tomcat/context.xml}}$
````
cd /opt/tomcat/apache-tomcat-9.0.89/conf/
vim context.xml
````
**add username ,password ,DB-Endpoint ,DB-name**
**add it under the context wor at the line of 21**
````
 <Resource name="jdbc/TestDB" auth="Container" type="javax.sql.DataSource"
               maxTotal="100" maxIdle="30" maxWaitMillis="10000"
               username="USERNAME" password="PASSWORD" driverClassName="com.mysql.jdbc.Driver"
               url="jdbc:mysql://DB-ENDPOINT:3306/DATABASE"/>
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/7160c2c6-c2cf-4890-a7bb-3871794b8173)

**Start Tomcat**
````
cd ../bin
chmod +x catalina.sh
./catalina.sh start
````
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/603153a3-bcc8-492a-b229-eb1255c7a63f)

### $\color{red} \textbf{Go \ To \ Browser \ Hit \ Public-IP \ Nginx}$
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/d3f4d112-daef-4dca-9c04-9e4841ba0887)


### $\color{red} \textbf{Here \ are \ the \ Output \ -Registered \ Student-Data}$
![image](https://github.com/guru6910/Single-tier-project-terraform/assets/169146749/3f6f7e8d-ecd3-45ff-8e84-3201bfdc8c04)
