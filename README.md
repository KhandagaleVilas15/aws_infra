# AWS Infrastructure (Terraform)

This repository provisions the AWS infrastructure for the application using Terraform. It sets up the VPC, Application Load Balancer (ALB), EC2 instances, networking components, and supporting services.

a) Deployment Steps

 Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.5 or newer installed

 1. Clone the repository


git clone <repo-url>
cd aws_infra


 2. Configure variables

Edit the `terraform.tfvars` file and set the required values, such as:

- **key_name** – Your EC2 key pair name 
- **alarm_email** – Email address for CloudWatch alarms
- **certificate_arn** – ACM certificate ARN (if using HTTPS; leave empty for HTTP only)

 3. Initialize Terraform
     terraform init

 4. Review the execution plan
    terraform plan

 5. Apply the configuration
      terraform apply


Type **yes** when prompted to confirm.

 6. Point your domain to the Load Balancer

After deployment completes:

terraform output alb_dns_name


Create a CNAME (or Alias record) in your DNS provider pointing your domain to the ALB DNS name.


b) Architecture Decisions

 Private App Servers

- EC2 instances are deployed in **private subnets** and do not have public IP addresses.
- All inbound traffic flows through the Application Load Balancer. This prevents direct internet access to the instances.

 NAT Gateway (Instead of NAT Instance)

We use an AWS-managed NAT Gateway rather than a self-managed NAT instance.

- No patching required
- No failover scripting
- Higher cost, but lower operational overhead

 Ubuntu 22.04 LTS

- Instances run **Ubuntu 22.04 LTS**.
- The application runs inside Docker (for example, Nginx). The ALB health check targets port 80 on each instance.

 IMDSv2 Only

- **Instance Metadata Service v2 (IMDSv2)** is enforced.
- The older metadata endpoint is disabled to reduce the risk of credential theft in case of compromise.

 Bastion Host (Optional)

- The bastion is **only** used for SSH login to private EC2 instances (no app traffic).
- If SSH access is required:
  - A small EC2 bastion host is deployed in a public subnet
  - Only IPs defined in **ssh_ingress_cidrs** can access it
- Alternatively, you can use **AWS Systems Manager Session Manager** and avoid exposing SSH entirely.

For a visual overview, see [docs/architecture.md](docs/architecture.md).

 c) Estimated Monthly Cost

Approximate monthly cost in **us-east-1** with default settings  
(2 app instances, 1 ALB, 1 NAT Gateway):

| Resource | Estimated Cost |
|----------|----------------|
| EC2 (2 × t3.small) | ~$30 |
| ApplnLB | ~$22 |
| NAT Gateway | ~$35 |
| EBS (root volumes) | ~$5 |
| CloudWatch | ~$5 |
| S3 / Miscellaneous | ~$2 |
| **Total** | **~$100/month** |

 d) Security Measures

- **EC2 instances** are in private subnets with no public IPs.

- **Security groups** restrict access:
  - Only the ALB can reach app instances on port 80
  - SSH to app servers only via bastion (or use SSM)

- **EBS volumes** are encrypted using AWS KMS.

- **No IAM access keys** stored in code:
  - EC2 instances use an IAM instance profile
  - GitHub Actions should use OIDC instead of storing AWS keys

- **S3 bucket** blocks all public access.

- **HTTPS support** via ACM certificate on the ALB; HTTP automatically redirects to HTTPS (when certificate is configured).

- **Secrets** should not be stored in Terraform files — use AWS Secrets Manager (or similar) for sensitive values.

- **IMDSv2** is enforced to prevent metadata abuse.

---

 e) Scaling Strategy

 Current Setup

- **Auto Scaling Group (ASG)** maintains 2–4 instances.
- Scales out when CPU usage exceeds threshold (CloudWatch alarm).
- Instances are behind the ALB.
- Launch template updates trigger rolling instance replacement.
- **ALB health checks** GET `/` on port 80; unhealthy instances are automatically replaced by the ASG.

