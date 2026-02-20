variable "project_name" {
  description = "Name prefix for security resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups and related resources are created"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "ssh_ingress_cidrs" {
  description = "CIDRs allowed to SSH into the bastion host "
  type        = list(string)
  default     = []
}
