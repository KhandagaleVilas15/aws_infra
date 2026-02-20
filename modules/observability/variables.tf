variable "project_name" {
  description = "Name prefix for observability resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "asg_name" {
  description = "Name of the Auto Scaling Group to monitor"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix for the ALB, used in CloudWatch metrics dimensions"
  type        = string
}

variable "tg_arn_suffix" {
  description = "ARN suffix for the ALB target group, used in CloudWatch metrics dimensions"
  type        = string
}

variable "alarm_email" {
  description = "Email address to receive alarm notifications"
  type        = string
}

