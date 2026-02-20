#!/usr/bin/env bash
# Import existing AWS resources into Terraform state.
# Use when resources were created outside this state (e.g. previous run, manual, or state lost).
#
# Usage:
#   cd /path/to/aws_infra
#   terraform init
#   export PROJECT_NAME=app-prod   # must match existing resource names in AWS
#   bash scripts/import-existing-resources.sh
#
# Or with Terraform vars (must match existing names):
#   PROJECT_NAME=app-prod bash scripts/import-existing-resources.sh

set -e
PROJECT_NAME="${PROJECT_NAME:-app-prod}"
REGION="${AWS_REGION:-us-east-1}"

echo "Importing resources for project_name=$PROJECT_NAME in $REGION"

# ECR repository (name only)
terraform import -var="project_name=$PROJECT_NAME" aws_ecr_repository.app "${PROJECT_NAME}-app" 2>/dev/null || true

# ALB and Target Group (need ARNs from AWS)
ALB_ARN=$(aws elbv2 describe-load-balancers --region "$REGION" --names "${PROJECT_NAME}-alb" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
  terraform import -var="project_name=$PROJECT_NAME" 'module.alb.aws_lb.main' "$ALB_ARN" 2>/dev/null || true
fi

TG_ARN=$(aws elbv2 describe-target-groups --region "$REGION" --names "${PROJECT_NAME}-tg" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
  terraform import -var="project_name=$PROJECT_NAME" 'module.alb.aws_lb_target_group.app' "$TG_ARN" 2>/dev/null || true
fi

# IAM role and instance profile (by name)
terraform import -var="project_name=$PROJECT_NAME" 'module.security.aws_iam_role.ec2' "${PROJECT_NAME}-ec2-role" 2>/dev/null || true
terraform import -var="project_name=$PROJECT_NAME" 'module.security.aws_iam_instance_profile.ec2' "${PROJECT_NAME}-ec2-profile" 2>/dev/null || true

# CloudWatch log groups (by name)
terraform import -var="project_name=$PROJECT_NAME" 'module.observability.aws_cloudwatch_log_group.app_access' /app/nginx/access 2>/dev/null || true
terraform import -var="project_name=$PROJECT_NAME" 'module.observability.aws_cloudwatch_log_group.app_error' /app/nginx/error 2>/dev/null || true
terraform import -var="project_name=$PROJECT_NAME" 'module.observability.aws_cloudwatch_log_group.ec2_user_data' /app/ec2/user-data 2>/dev/null || true

# Budget (AccountId:BudgetName) — only if you have alarm_email set so the resource exists
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || true)
if [ -n "$ACCOUNT_ID" ]; then
  terraform import -var="project_name=$PROJECT_NAME" 'module.observability.aws_budgets_budget.monthly[0]' "${ACCOUNT_ID}:${PROJECT_NAME}-monthly-budget" 2>/dev/null || true
fi

echo "Import done. Run: terraform plan -var=\"project_name=$PROJECT_NAME\" to verify."
