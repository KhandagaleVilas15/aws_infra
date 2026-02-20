output "asg_name" {
  description = "Name of the Auto Scaling Group for application instances"
  value       = aws_autoscaling_group.app.name
}

output "bastion_public_ip" {
  description = "Public IP of bastion (if enabled)"
  value       = try(aws_instance.bastion[0].public_ip, null)
}

output "bastion_public_dns" {
  description = "Public DNS of bastion (if enabled)"
  value       = try(aws_instance.bastion[0].public_dns, null)
}

