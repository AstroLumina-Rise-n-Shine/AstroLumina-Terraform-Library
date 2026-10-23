# AstroLumina-Terraform-Library

Reusable Terraform modules for the AstroLumina platform: KVM virtual machines
on libvirt and AWS resources developed against the Floci emulator.

The live infrastructure composition (development / staging / production) lives
in [AstroLumina-Terraform](https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform).
Hands-on labs, the AWS learning path and the Floci setup guides live in
[AstroLumina-AWS](https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-AWS).

## Layout

```
modules/
  kvm_vm/                 # Single KVM virtual machine (libvirt + cloud-init)
  aws_eks/                # EKS cluster + managed node group (control plane managed by AWS)
  aws_network/            # VPC, public/private subnets, internet gateway, optional NAT
  aws_s3_bucket/          # S3 bucket + versioning, SSE, public-access block
  aws_dynamodb_table/     # DynamoDB table with optional range key and TTL
  aws_ec2_instance/       # Single EC2 instance in a given subnet
  aws_lambda_function/    # Lambda function from a local zip package
  aws_ecs_fargate/        # ECS cluster + Fargate task definition and service
  aws_rds/                # RDS instance in a dedicated DB subnet group
  aws_elasticache_redis/  # Single-node ElastiCache Redis replication group (private, encrypted)
  aws_iam_role/           # IAM role with managed/inline policies
  aws_iam_user/           # IAM user with policies and optional access key
  aws_cross_account_role/ # Role that trusts another AWS account (cross-account AssumeRole)
  aws_route53_zone/       # Route 53 hosted zone + records
  aws_alb/                # Application Load Balancer + target group + HTTP listener
  aws_vpn/                # Site-to-site VPN gateway, customer gateway, connection
  aws_security_baseline/  # KMS key, GuardDuty, Security Hub, CloudTrail baseline
  aws_budget/             # AWS Budget + SNS notifications for cost alerts
```
