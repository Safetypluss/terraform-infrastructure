#test
# Configure the AWS Provider
provider "aws" {
  region  = "us-east-1"
#Authentication setup
  access_key = var.access_key
  secret_key = var.secret_key
}

#how to create a vpc
resource "aws_vpc" "damy_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "damy_vpc"
  }
}
#creating an internet gateway
resource "aws_internet_gateway" "damy_gt" {
  vpc_id = aws_vpc.damy_vpc.id

  tags = {
    Name = "damy_internet_gateway"
  }
}
#creating a route table
resource "aws_route_table" "damy_route_table" {
  vpc_id = aws_vpc.damy_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.damy_gt.id
  }

  /*route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_egress_only_internet_gateway.damy_gt.id
  }*/
  tags = {
    Name = "dammy_route"
  }
}
#creating a subnet
resource "aws_subnet" "damy_subnet" {
  vpc_id     = aws_vpc.damy_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "dammy_subnet"
  }
}

resource "aws_subnet" "demy_subnet" {
  vpc_id     = aws_vpc.damy_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "demmy_subnet"
  }
}

#associate subnet with route table
resource "aws_route_table_association" "damy_route_table_association" {
  subnet_id      = aws_subnet.damy_subnet.id
  route_table_id = aws_route_table.damy_route_table.id
}
resource "aws_route_table_association" "demy_route_table_association" {
  subnet_id      = aws_subnet.demy_subnet.id
  route_table_id = aws_route_table.damy_route_table.id
}

#creating a Network Acl
resource "aws_network_acl" "damy_network_acl" {
  vpc_id     = aws_vpc.damy_vpc.id
  subnet_ids = [aws_subnet.damy_subnet.id, aws_subnet.demy_subnet.id]
ingress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
}

#create security group that allows 22, 80 and 443
resource "aws_security_group" "damy_web_server" {
  name        = "allow_web"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.damy_vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }

 ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
   # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]
  }
 
  
  egress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    #ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}
#create a network interface with an IP created in the subnet created earlier
resource "aws_network_interface" "damy_network_interface" {
  subnet_id       = aws_subnet.damy_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.damy_web_server.id]

}

 # attachment {
    #instance     = aws_instance.test.id
    #device_index = 1
 # }
#}
#Attaching an EIP to an Instance with a pre-assigned private ip (VPC Only):
/*resource "aws_vpc" "damy_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}*/

/*resource "aws_internet_gateway" "damy_internet_gateway" {
  vpc_id = aws_vpc.damy_vpc.id
}*/

/*resource "aws_subnet" "damy_subnet" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.damy_gt]
}*/

# Create a security group for the load balancer
resource "aws_security_group" "damy_load_balancer_sg" {
  name        = "damy_load_balancer_sg"
  description = "Security group for the load balancer"
  vpc_id      = aws_vpc.damy_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Create Security Group to allow port 22, 80 and 443
resource "aws_security_group" "damy_security_grp_rule" {
  name        = "allow_ssh_http_https"
  description = "Allow SSH, HTTP and HTTPS inbound traffic for private instances"
  vpc_id      = aws_vpc.damy_vpc.id
 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.damy_load_balancer_sg.id]
  }
 ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.damy_load_balancer_sg.id]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
   
  }
  tags = {
    Name = "damy_security_grp_rule"
  }
}

resource "aws_instance" "first_instance" {
  # us-west-2
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  key_name   = "man"
  security_groups =[aws_security_group.damy_security_grp_rule.id]
  availability_zone = "us-east-1b"
  
  private_ip = "10.0.2.16"
  subnet_id  = aws_subnet.demy_subnet.id
  tags = {
    Name   = "Nigeria"
    source = "terraform"
  }
  user_data = <<-EOF
     #!/bin/bash
     sudo apt upgrade -y
     sudo apt update -y
     sudo apt install ansible -y
     sudo systemctl start ansible.service
     sudo systemctl enable ansible.service
     EOF

}

/*resource "aws_eip" "bar" {
  vpc = true

  instance                  = aws_instance.first_instance.id
  associate_with_private_ip = "10.0.2.16"
  depends_on                = [aws_internet_gateway.damy_gt]
}*/

resource "aws_instance" "second_instance" {
  # us-west-2
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  key_name   = "man"
  security_groups =[aws_security_group.damy_security_grp_rule.id]
  availability_zone = "us-east-1a"
  private_ip = "10.0.1.24"
  subnet_id  = aws_subnet.damy_subnet.id
  tags = {
    Name   = "USA"
    source = "terraform"
  }
  user_data = <<-EOF
     #!/bin/bash
     sudo apt upgrade -y
     sudo apt update -y
     sudo apt install ansible -y
     sudo systemctl start ansible.service
     sudo systemctl enable ansible.service
     EOF
}

/*resource "aws_eip" "barr" {
  vpc = true

  instance                  = aws_instance.second_instance.id
  associate_with_private_ip = "10.0.1.24"
  depends_on                = [aws_internet_gateway.damy_gt]
}*/

resource "aws_instance" "third_instance" {
  # us-west-2
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  key_name   = "man"
  security_groups =[aws_security_group.damy_security_grp_rule.id]
  availability_zone = "us-east-1b"
  private_ip = "10.0.2.30"
  subnet_id  = aws_subnet.demy_subnet.id
  tags = {
    Name   = "Canada"
    source = "terraform"
  }
  user_data = <<-EOF
     #!/bin/bash
     sudo apt upgrade -y
     sudo apt update -y
     sudo apt install ansible -y
     sudo systemctl start ansible.service
     sudo systemctl enable ansible.service
     EOF
}

/*resource "aws_eip" "barrr" {
  vpc = true

  instance                  = aws_instance.third_instance.id
  associate_with_private_ip = "10.0.2.30"
  depends_on                = [aws_internet_gateway.damy_gt]
  
}*/

#target group
resource "aws_lb_target_group" "damy_tg" {
  name = "damy-tg"
  target_type = "instance"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.damy_vpc.id
  health_check {
        interval            = 30
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        timeout             = 5
        healthy_threshold   = 5
        unhealthy_threshold  = 2
    }
}


#creating a load balancer
resource "aws_lb" "damy_elb" {
  name               = "damy-elb"
  internal           = false
  ip_address_type    = "ipv4"  
  load_balancer_type = "application"
  security_groups = [aws_security_group.damy_load_balancer_sg.id]
  #security_groups    = [aws_security_group.damy_web_server.id]
  subnets            = [aws_subnet.damy_subnet.id, aws_subnet.demy_subnet.id]
#enable_cross_zone_load_balancing = true
  enable_deletion_protection = false
  depends_on                 = [aws_instance.first_instance, aws_instance.second_instance, aws_instance.third_instance]
}  
  /*tags = {
      name = "damy-elb"
  }*/

#creating a listener
resource "aws_lb_listener" "damy_listener" {
  load_balancer_arn             = aws_lb.damy_elb.arn
  port                          = 80
  protocol                      = "HTTP"
  default_action {
      target_group_arn            = aws_lb_target_group.damy_tg.arn
      type                        = "forward"
  }
}
# Create the listener rule
resource "aws_lb_listener_rule" "damy_listener_rule" {
  listener_arn = aws_lb_listener.damy_listener.arn
  priority     = 1
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.damy_tg.arn
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

#Attachment
resource "aws_lb_target_group_attachment" "ec2_first_attach" {
    count = length(aws_instance.first_instance)
    target_group_arn = aws_lb_target_group.damy_tg.arn
    target_id = aws_instance.first_instance.id
    port = 80
}

resource "aws_lb_target_group_attachment" "ec2_second_attach" {
    count = length(aws_instance.second_instance)
    target_group_arn = aws_lb_target_group.damy_tg.arn
    target_id = aws_instance.second_instance.id
    port = 80
}

resource "aws_lb_target_group_attachment" "ec2_third_attach" {
    count = length(aws_instance.third_instance)
    target_group_arn = aws_lb_target_group.damy_tg.arn
    target_id = aws_instance.third_instance.id
    port = 80
}
output "elb-dns-name" {

    value   = aws_lb.damy_elb.dns_name
}

resource "local_file" "Ip_address" {
  filename = "C:/Users/DELL/Desktop/Terraform/terraform project/host-inventory.tfvars"
  content  = <<EOT
${aws_instance.first_instance.public_ip}
${aws_instance.second_instance.public_ip}
${aws_instance.third_instance.public_ip}
  EOT
}
/*resource "null_resource" "ansible-playbook" {
  provisioner "local-exec" {
    command = "ansible-playbook --private-key man.pem ansible.yml -i host inventory"
  }
}
/*provisioner "local-exec" {
command = "ansible-playbook ansible.yml -i host-inventory"
}
}*/


 /* subnet_mapping {
    subnet_id            = aws_subnet.damy_subnet.id
    private_ipv4_address = "10.0.1.16"
  }

  subnet_mapping {
    subnet_id            = aws_subnet.damy_subnet.id
    private_ipv4_address = "10.0.1.24"
  }
C:\Users\DELL\Desktop\Terraform\terraform project
  subnet_mapping {
    subnet_id            = aws_subnet.demy_subnet.id
    private_ipv4_address = "10.0.2.30"
  }
}
/*resource "aws_lb" "tame" {
  name               = "tame-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.damy_web_server.id]
  subnets            = [for subnet in aws_subnet.public : damy_subnet.id]

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "tame-lb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}

#connecting to Elastic IP

#creating an ubuntu server (instance)
/*resource "aws_instance" "my_firstserver" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  Key_name = "human_key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.damy_network_interface.id
  }
  tags = {
    Name = "USA"
  }
}

resource "aws_instance" "my_secondserver" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  Key_name = "human"

   network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.damy_network_interfacee.id
   }
  tags = {
    Name = "Uk"
  }
}

resource "aws_instance" "my_thirdserver" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a" 
  Key_name = "human"

   network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.damy_network_interfaceee.id
   }
  tags = {
    Name = "canada"
  }
}
   /*user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update-y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo bash -c 'echo my very first web server > /var/www/html/index.html'
                 EOF
  tags = {
    Name = "Damilare_server"
}*/
