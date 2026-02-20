
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State in S3 so CI and local share state. Configure with -backend-config or backend.hcl.
  # Example: terraform init -backend-config="bucket=YOUR_BUCKET" -backend-config="region=us-east-1"
  backend "s3" {
    bucket         = "my-terraform-statebucket123"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "CloudTeam"
    }
  }
}

data "aws_caller_identity" "current" {}


# AMI (auto-detect if var.ami_id is empty)

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  effective_ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
}


# Container Registry (ECR)

resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.ecr_repo_name}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images (keep last 10)"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

# VPC & Networking
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}


# Security Groups

module "security" {
  source = "./modules/security"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  ssh_ingress_cidrs = var.ssh_ingress_cidrs
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  certificate_arn   = var.certificate_arn
}


# EC2 Auto Scaling + NGINX

module "compute" {
  source = "./modules/compute"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  ec2_sg_id                 = module.security.ec2_sg_id
  bastion_sg_id             = module.security.bastion_sg_id
  ec2_instance_profile_name = module.security.ec2_instance_profile_name
  instance_type             = var.instance_type
  ami_id                    = local.effective_ami_id
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_desired_capacity
  target_group_arn          = module.alb.target_group_arn
  key_name                  = var.key_name
  public_subnet_id          = module.vpc.public_subnet_ids[0]
  enable_bastion            = var.enable_bastion
  bastion_instance_type     = var.bastion_instance_type

  enable_container_app = var.enable_container_app
  app_image            = "nginx:latest"
  app_container_port   = var.app_container_port

  # Explicit dependency to ensure ALB target group exists before ASG creation
  depends_on = [module.alb]
}

# Observability (CloudWatch Logs + Alarms)

module "observability" {
  source = "./modules/observability"

  project_name   = var.project_name
  environment    = var.environment
  asg_name       = module.compute.asg_name
  alb_arn_suffix = module.alb.alb_arn_suffix
  tg_arn_suffix  = module.alb.target_group_arn_suffix
  alarm_email    = var.alarm_email
}
