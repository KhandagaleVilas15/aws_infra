
# outputs.tf — Useful values after apply

output "vpc_id" {
  description = "The VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer — point your domain here"
  value       = module.alb.alb_dns_name
}

output "app_url" {
  description = "Use this URL in the browser (HTTP only when certificate_arn is empty). If nginx does not respond, check Target Group health in AWS Console."
  value       = "http://${module.alb.alb_dns_name}"
}

output "ecr_repository_url" {
  description = "ECR repository URL (push images here)"
  value       = aws_ecr_repository.app.repository_url
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID for ALB (for alias records)"
  value       = module.alb.alb_zone_id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.asg_name
}

output "bastion_public_ip" {
  description = "Public IP of bastion host (SSH entry point)"
  value       = module.compute.bastion_public_ip
}

output "bastion_public_dns" {
  description = "Public DNS of bastion host (SSH entry point)"
  value       = module.compute.bastion_public_dns
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB lives here)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (EC2 lives here)"
  value       = module.vpc.private_subnet_ids
}
