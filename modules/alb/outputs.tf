output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route 53 hosted zone ID for ALB (for alias records)"
  value       = aws_lb.main.zone_id
}

output "alb_arn_suffix" {
  description = "ARN suffix used by CloudWatch metrics for the ALB"
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix used by CloudWatch metrics for the target group"
  value       = aws_lb_target_group.app.arn_suffix
}

output "target_group_arn" {
  description = "Full ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

