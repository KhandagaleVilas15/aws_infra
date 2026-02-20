variable "project_name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the ALB will live"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security group ID to attach to the ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for the HTTPS listener; leave empty to use HTTP only"
  type        = string
  default     = ""
}
