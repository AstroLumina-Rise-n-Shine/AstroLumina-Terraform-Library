# aws_network

Creates a complete VPC network scaffold: one VPC, an internet gateway,
public and private subnets, matching route tables with the right default
routes, and an optional single NAT gateway. It is the "ground floor" that
other AstroLumina modules (EC2, ECS, RDS, ALB) expect to stand on — you
usually call it once per environment and hand the subnet IDs to everything
built on top.

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
