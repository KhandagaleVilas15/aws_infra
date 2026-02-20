variable "project_name" {
  description = "Name prefix for compute resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region (used for ECR login)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for compute resources (currently unused but passed for future use)"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs where EC2 instances will run"
  type        = list(string)
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
  default     = null
}

variable "ec2_sg_id" {
  description = "Security group ID for EC2 instances"
  type        = string
}

variable "bastion_sg_id" {
  description = "Security group ID for bastion host"
  type        = string
  default     = null
}

variable "ec2_instance_profile_name" {
  description = "IAM instance profile name for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
}

variable "target_group_arn" {
  description = "ARN of the ALB target group to attach the ASG to"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "enable_bastion" {
  description = "Whether to create a public bastion instance"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for bastion"
  type        = string
  default     = "t4g.micro"
}

variable "bastion_ami_id" {
  description = "AMI ID for bastion (defaults to app AMI)"
  type        = string
  default     = null
}

variable "app_image" {
  description = "Full container image URI to run on app instances (ECR recommended), e.g. 123.dkr.ecr.us-east-1.amazonaws.com/repo:tag"
  type        = string
  default     = ""
}

variable "app_container_port" {
  description = "Container port your Node app listens on (inside container)"
  type        = number
  default     = 80
}

variable "enable_container_app" {
  description = "If true, install Docker and run app container from app_image"
  type        = bool
  default     = true
}

