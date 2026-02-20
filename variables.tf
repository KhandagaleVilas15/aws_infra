
variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "app-prod"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

# ── Networking 
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (min 2 for HA)"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "nat_eip_allocation_id" {
  description = "Existing EIP allocation ID for the NAT gateway. Set when at EIP limit; leave empty to create a new EIP."
  type        = string
  default     = ""
}

# ── Compute 
variable "ami_id" {
  description = "AMI ID for EC2 instances. Leave empty to auto-detect latest Amazon Linux 2023 AMI."
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type. Use x86_64 types (e.g. t3.small) with default Ubuntu AMI; use t4g.* for ARM with ami_architecture = arm64."
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH (optional)"
  type        = string
  default     = ""
}

variable "ssh_ingress_cidrs" {
  description = "CIDRs allowed to SSH into the bastion host (e.g. [\"1.2.3.4/32\"]). Empty disables SSH ingress."
  type        = list(string)
  default     = []
}

variable "enable_bastion" {
  description = "Whether to create a public bastion instance"
  type        = bool
  default     = true
}

variable "bastion_instance_type" {
  description = "Instance type for bastion (must match AMI architecture: x86_64 e.g. t3.micro, or arm64 e.g. t4g.micro)"
  type        = string
  default     = "t3.micro"
}

variable "ecr_repo_name" {
  description = "ECR repository name for the application image"
  type        = string
  default     = "app"
}

variable "app_image_tag" {
  description = "Docker image tag to deploy (use immutable tags like git SHA or semver)"
  type        = string
  default     = "latest"
}

variable "app_container_port" {
  description = "Container port your Node app listens on (inside container)"
  type        = number
  default     = 80
}

variable "enable_container_app" {
  description = "If true, instances will run the Node app as a Docker container pulled from ECR"
  type        = bool
  default     = true
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 6
}

variable "asg_desired_capacity" {
  description = "Desired number of EC2 instances"
  type        = number
  default     = 2
}

# ── ALB / HTTPS (optional) 
variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener on ALB; leave empty to use HTTP only"
  type        = string
  default     = ""
}

# ── Observability 
variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
  default     = ""
}
variable "alarm_email_list" {
  description = "List of email addresses to receive CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}