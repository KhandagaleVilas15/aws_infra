
# modules/compute/main.tf
# EC2 Launch Template + Auto Scaling Group + NGINX
locals {
  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region           = var.aws_region
    enable_container_app = var.enable_container_app
    app_image            = var.app_image
    app_container_port   = var.app_container_port
  }))
}

# ── EBS Encryption Key (KMS) 
data "aws_kms_key" "ebs" {
  key_id = "alias/aws/ebs"
}

# ── Launch Template 
resource "aws_launch_template" "app" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  # IAM instance profile — gives EC2 permission to call SSM, CloudWatch APIs
  iam_instance_profile {
    name = var.ec2_instance_profile_name
  }

  # Key pair for SSH access - explicitly set for app instances
  # When key_name is provided, it will be set; when empty string, it will be null (no key)
  key_name = var.key_name != "" ? var.key_name : null

  # Security groups - ASG will place instances in subnets specified by vpc_zone_identifier
  vpc_security_group_ids = [var.ec2_sg_id]

  # Encrypted EBS root volume
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = data.aws_kms_key.ebs.arn
      delete_on_termination = true
    }
  }

  # IMDSv2 required — blocks SSRF attacks from stealing credentials
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = local.user_data

  lifecycle {
    create_before_destroy = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-app-server" }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = { Name = "${var.project_name}-app-volume" }
  }
}

# ── Auto Scaling Group 
resource "aws_autoscaling_group" "app" {
  name                = "${var.project_name}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [var.target_group_arn]

  health_check_type         = "ELB"
  health_check_grace_period = 420 

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # Zero-downtime rolling replacement
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-app-server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── Scaling Policies 
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.project_name}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.project_name}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

# Public Bastion (Jump Host) — SSH entry point

resource "aws_instance" "bastion" {
  count = var.enable_bastion ? 1 : 0

  ami           = coalesce(var.bastion_ami_id, var.ami_id)
  instance_type = var.bastion_instance_type
  subnet_id     = var.public_subnet_id

  vpc_security_group_ids      = [var.bastion_sg_id]
  associate_public_ip_address = true

  key_name = var.key_name != "" ? var.key_name : null

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    kms_key_id            = data.aws_kms_key.ebs.arn
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-bastion"
    Tier = "public"
  }
}
