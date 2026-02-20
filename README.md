# AWS infra (Terraform)

This repo sets up the AWS stuff for the app: VPC, load balancer, EC2 instances behind it, and a few other bits. Everything is in Terraform.



 a) Deployment steps

You need AWS CLI set up and Terraform 1.5 or newer.

1. **Get the code**
 
   git clone <your-repo-url>

   cd aws_infra
 

2. **Set your settings**  
   Edit `terraform.tfvars`. You’ll want to set things like `key_name` (your EC2 key), `alarm_email`, and if you use HTTPS, `certificate_arn`.

3. **Init Terraform**

   terraform init


4.terraform plan


5.  terraform apply
   Type `yes` when it asks.

6. **Point your domain**  
   After apply, run `terraform output alb_dns_name` and point your domain (CNAME or Alias) to that ALB address.


 b) Architecture decisions

 **App servers in private subnets**  
  EC2 instances don’t get a public IP. All traffic goes through the load balancer. So even if something is broken, you can’t hit the instances directly from the internet.

 **NAT Gateway instead of a NAT instance**  
  NAT Gateway is managed by AWS. No patching, no failover scripts. It costs a bit more but we don’t have to babysit it.

  **Ubuntu on the instances**  
  We use Ubuntu 22.04 LTS. The app runs in Docker (e.g. nginx) so the ALB health check hits port 80 on the instance.

 **IMDSv2 only**  
  We turn off the old instance metadata endpoint. That way if something on the box gets hacked, it’s harder to steal IAM creds from metadata.

 **Bastion for SSH (optional)**  
  If you need SSH, you go through one small EC2 in a public subnet. Only IPs you put in `ssh_ingress_cidrs` can reach it. You can also use SSM Session Manager and skip opening SSH at all.



 c) Cost estimate

Rough monthly cost in us-east-1 with the defaults (2 app instances, 1 ALB, 1 NAT Gateway):

| Thing            | Rough cost |
|------------------|------------|
| EC2 (2 × t3.small) | ~\$30   |
| Load balancer    | ~\$22     |
| NAT Gateway      | ~\$35     |
| EBS (root disks) | ~\$5      |
| CloudWatch       | ~\$5      |
| S3 / other       | ~\$2      |
| **Total**        | **~\$100/month** |



d) Security measures

 App EC2s are in **private subnets**, no public IPs.

 **Security groups**: only the ALB can talk to app instances on port 80. SSH to app servers only from the bastion (or use SSM).

 **EBS** volumes are encrypted (AWS KMS).

  **No IAM keys in code**. EC2 uses an instance profile. If you use GitHub Actions, use OIDC so you don’t store AWS keys in GitHub.

  **S3** bucket has all public access blocked.

 **HTTPS**: if you set `certificate_arn`, the ALB does TLS and redirects HTTP to HTTPS.

 **Secrets**: don’t put real secrets in tfvars or code. Use AWS Secrets Manager (or similar) for app 
secrets.

 **IMDSv2** is required on instances so the old metadata API can’t be abused.




 e) Scaling strategy

 **Right now**: an Auto Scaling Group keeps 2–6 instances. It scales up when CPU gets high (CloudWatch alarm). Instances sit behind the ALB; when we change the launch template, the ASG does a rolling replace so we don’t take everything down at once.
 **Health checks**: the ALB checks `/` on port 80. If an instance fails enough checks, it’s marked unhealthy and the ASG replaces it.
 **If we extend it later**: we could scale on request count instead of CPU, add a CDN in front, or put WAF on the ALB. For a database we’d add RDS/Aurora in private subnets.




