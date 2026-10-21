# aws_network

Creates a complete VPC network scaffold: one VPC, an internet gateway,
public and private subnets, matching route tables with the right default
routes, an optional single NAT gateway, and VPC Flow Logs to CloudWatch
Logs by default (Trivy AWS-0178). It is the "ground floor" that other
AstroLumina modules (EC2, ECS, RDS, ALB) expect to stand on — you usually
call it once per environment and hand the subnet IDs to everything built
on top.

The flow-log role trust policy pins `aws:SourceAccount` plus the
`vpc-flow-log/*` ARN for this account and region. AWS evaluates that
condition against the flow-log ARN (not the VPC ARN); the flow-log ID does
not exist until the flow log is created, so the policy uses the wildcard
fallback AWS documents for that case. The inline policy keeps
`CreateLogStream`/`PutLogEvents` scoped to the one log group. The
`DescribeLogGroups`/`DescribeLogStreams` pair is granted on `*`, matching
AWS's flow-log role policy (`DescribeLogGroups` has no resource type at all).

## Usage

```hcl
module "network" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_network?ref=main"

  name        = "lab-network"
  environment = "lab"

  cidr_block         = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = true
}
```

## Inputs

| Name                 | Type          | Default                          | Description                                                                                                                                              |
|----------------------|---------------|----------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                 | string        | -                                | VPC name, also prefixes subnet and route-table names                                                                                                     |
| cidr_block           | string        | `10.0.0.0/16`                    | CIDR block for the whole VPC -- pick an IP range nothing else in your estate already uses                                                                |
| availability_zones   | list(string)  | `[]`                             | Optional AZ names, assigned positionally (first CIDR into first AZ, and so on). Empty means the emulator/region picks for you. On real AWS pass enough AZs to spread subnets across multiple zones for HA. |
| public_subnet_cidrs  | list(string)  | `["10.0.1.0/24", "10.0.2.0/24"]` | CIDRs for the public subnets (internet-facing tier)                                                                                                      |
| private_subnet_cidrs | list(string)  | `["10.0.11.0/24", "10.0.12.0/24"]` | CIDRs for the private subnets (internal tier)                                                                                                          |
| enable_nat_gateway   | bool          | `false`                          | One NAT gateway for all private subnets (cost-conscious default: off)                                                                                    |
| enable_flow_logs     | bool          | `true`                           | Capture ALL VPC flows to CloudWatch Logs through a scoped IAM role (Trivy AWS-0178). CloudWatch ingestion is billed on real AWS                           |
| flow_logs_retention_days | number    | `7`                              | Days VPC Flow Log records are kept in CloudWatch Logs                                                                                                     |
| flow_logs_traffic_type | string      | `ALL`                            | Which flows to capture: ALL, ACCEPT or REJECT                                                                                                             |
| create_flow_logs_kms_key | bool      | `true`                           | Create a dedicated rotating CMK for the flow-log group (Trivy AWS-0017). A CMK costs about $1/month on real AWS                                           |
| flow_logs_kms_key_arn | string     | `null`                           | Existing CMK ARN for the flow-log group instead of creating one                                                                                           |
| environment          | string        | -                                | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags                 | map(string)   | `{}`                             | Extra tags applied to every created object                                                                                                               |

## Outputs

| Name                  | Description                                                                                     |
|-----------------------|-------------------------------------------------------------------------------------------------|
| vpc_id                | ID of the created VPC                                                                            |
| vpc_cidr_block        | CIDR block of the created VPC                                                                    |
| public_subnet_ids     | IDs of the public subnets (internet-facing tier)                                                 |
| private_subnet_ids    | IDs of the private subnets (internal tier)                                                       |
| internet_gateway_id   | ID of the internet gateway attached to the VPC                                                   |
| nat_gateway_ids       | IDs of the NAT gateways (list with one entry when enabled, empty when disabled)                   |
| flow_log_id           | ID of the VPC Flow Log (null when disabled)                                                      |
| flow_logs_log_group_name | Name of the CloudWatch Logs group receiving VPC Flow Logs (null when disabled)                 |
| flow_logs_role_arn    | ARN of the IAM role VPC Flow Logs assumes to write to CloudWatch Logs (null when disabled)        |
| flow_logs_kms_key_arn | ARN of the CMK encrypting the flow-log group (null when disabled or key creation was opted out)   |

## Floci note

The flow-log path needs `logs`, `iam` and `kms` endpoints in addition to
`ec2`: `logs = "http://localhost:4566"`, `iam = "http://localhost:4566"`
and `kms = "http://localhost:4566"`.
