```hcl
# Define the provider
provider "aws" {
  region = "us-east-1" # Replace with your desired region
}

# VPC and Networking
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "three-tier-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# Security Groups
module "security_groups" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name   = "three-tier-sg"
  vpc_id = module.vpc.vpc_id

  ingress_rules       = ["https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules = ["all-all"]
}

# Load Balancer
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "three-tier-alb"

  load_balancer_type = "application"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.security_groups.security_group_id]
}

# Web Tier
module "web_tier" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = "three-tier-web"

  vpc_zone_identifier = module.vpc.private_subnets
  min_size            = 2
  max_size            = 5
  desired_capacity    = 2

  security_groups = [module.security_groups.security_group_id]
  target_group_arns = module.alb.target_group_arns

  instance_type = "t2.micro"
  image_id      = "ami-0cff7528ff583bf9a" # Replace with your desired AMI

  user_data = <<-EOF
              #!/bin/bash
              echo "Web Server User Data"
              # Install and configure your web server
              EOF
}

# Application Tier
module "app_tier" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 4.0"

  name = "three-tier-app"

  vpc_zone_identifier = module.vpc.private_subnets
  min_size            = 2
  max_size            = 5
  desired_capacity    = 2

  security_groups = [module.security_groups.security_group_id]

  instance_type = "t2.micro"
  image_id      = "ami-0cff7528ff583bf9a" # Replace with your desired AMI

  user_data = <<-EOF
              #!/bin/bash
              echo "Application Server User Data"
              # Install and configure your application
              EOF
}

# Data Tier
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "three-tier-rds"

  engine            = "mysql"
  engine_version    = "5.7.33"
  instance_class    = "db.t2.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "mydb"
  username = "myuser"
  password = "mypassword"

  vpc_security_group_ids = [module.security_groups.security_group_id]

  multi_az               = true
  subnet_ids             = module.vpc.private_subnets
  publicly_accessible    = false
  create_random_password = false

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
}
```

This Terraform code defines the following resources:

1. **VPC and Networking**: Creates a VPC with public and private subnets across multiple Availability Zones, along with the necessary networking components like internet gateways, NAT gateways, and route tables.

2. **Security Groups**: Defines a security group that allows inbound HTTPS traffic from anywhere and outbound traffic to anywhere.

3. **Load Balancer**: Creates an Application Load Balancer (ALB) in the public subnets, which will be used to distribute traffic to the web servers.

4. **Web Tier**: Defines an Auto Scaling group for the web servers in the private subnets. The instances will be launched using the specified AMI and user data script.

5. **Application Tier**: Defines an Auto Scaling group for the application servers in the private subnets. The instances will be launched using the specified AMI and user data script.

6. **Data Tier**: Creates a Multi-AZ MySQL RDS instance in the private subnets, with the specified database name, username, and password.

Note: You will need to replace the placeholders (e.g., AMI IDs, database credentials) with your desired values. Additionally, you may need to adjust the resource configurations based on your specific requirements, such as instance types, scaling policies, and other settings.