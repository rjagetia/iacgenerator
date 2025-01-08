```hcl
# Define AWS provider
provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main VPC"
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a" # Replace with your desired AZ

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b" # Replace with your desired AZ

  tags = {
    Name = "Public Subnet 2"
  }
}

# Private Subnets
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a" # Replace with your desired AZ

  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b" # Replace with your desired AZ

  tags = {
    Name = "Private Subnet 2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main Internet Gateway"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "NAT Gateway 1"
  }
}

resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "NAT Gateway 2"
  }
}

resource "aws_eip" "nat_eip_1" {
  vpc   = true
  tags = {
    Name = "NAT EIP 1"
  }
}

resource "aws_eip" "nat_eip_2" {
  vpc   = true
  tags = {
    Name = "NAT EIP 2"
  }
}

# Security Groups and NACLs
# Define security groups and NACLs as needed

# Application Tier
resource "aws_launch_configuration" "app_launch_config" {
  # Define instance type and AMI
  instance_type = "t2.micro"
  image_id      = "ami-0cff7528ff583bf9a" # Replace with your desired AMI

  # Define other configurations as needed
}

resource "aws_autoscaling_group" "app_asg" {
  name                      = "App ASG"
  max_size                  = 3
  min_size                  = 2
  desired_capacity          = 2
  launch_configuration      = aws_launch_configuration.app_launch_config.name
  vpc_zone_identifier       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"

  # Define other configurations as needed
}

# Database Tier
resource "aws_db_instance" "rds_instance" {
  engine                 = "mysql"
  engine_version         = "5.7" # Replace with your desired version
  instance_class         = "db.t3.micro" # Replace with your desired instance type
  allocated_storage      = 20 # Replace with your desired storage size
  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.private_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  # Define other configurations as needed
}

resource "aws_db_subnet_group" "private_subnets" {
  name       = "private-subnets"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "Private Subnets for RDS"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "RDS Security Group"
  vpc_id      = aws_vpc.main.id

  # Define inbound and outbound rules as needed
}

# Load Balancer
resource "aws_lb" "app_lb" {
  name               = "App Load Balancer"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  security_groups    = [aws_security_group.lb_sg.id]

  # Define other configurations as needed
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "App Target Group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_security_group" "lb_sg" {
  name        = "Load Balancer Security Group"
  vpc_id      = aws_vpc.main.id

  # Define inbound and outbound rules as needed
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name = "Private Route Table"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_subnet_1_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_2_assoc" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
```

This Terraform code creates the necessary infrastructure based on the provided architecture diagram and requirements. It includes the VPC, subnets, internet gateway, NAT gateways, security groups, Auto Scaling group for the application tier, RDS MySQL Multi-AZ instance for the database tier, and an Application Load Balancer. The code also configures the necessary route tables and associations.

Note: You may need to adjust the configurations based on your specific requirements, such as instance types, AMIs, and security group rules.