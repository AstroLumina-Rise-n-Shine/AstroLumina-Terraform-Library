# aws_ec2_instance

Creates exactly one EC2 instance in a subnet the caller names, with all
infrastructure inputs (AMI, subnet, security groups) passed in explicitly —
the module performs zero data-source lookups. Defaults assume a simple
learning setup: t3.micro with an auto-assigned public IP; drop the public
IP for anything that should only be reachable privately.

## Usage

```hcl
module "workhorse" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_ec2_instance?ref=main"

  name        = "lab-build-box"
  environment = "lab"

  ami          = "ami-00000000"
  subnet_id    = module.network.public_subnet_ids[0]
  instance_type = "t3.micro"
}
```

## Inputs

| Name                         | Type        | Default    | Description                                                                                                                                                                                         |
|------------------------------|-------------|------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                         | string      | -          | Instance name -- also stamped as the Name tag                                                                                                                                                        |
| ami                          | string      | -          | AMI ID. Floci maps any AMI ID to its local runtime image; real AWS needs a real AMI.                                                                                                                 |
| instance_type                | string      | `t3.micro` | EC2 instance size/shape                                                                                                                                                                              |
| subnet_id                    | string      | -          | Subnet the instance is launched into (no lookup, caller passes the ID)                                                                                                                               |
| security_group_ids           | list(string)| `[]`       | Security group IDs attached to the instance's primary network interface                                                                                                                              |
| key_name                     | string      | `null`     | SSH key pair name for the instance; null (fine on Floci) means no SSH key                                                                                                                            |
| user_data                    | string      | `null`     | Optional cloud-init / shell script executed on first boot                                                                                                                                            |
| associate_public_ip_address  | bool        | `true`     | Whether the instance's primary interface auto-assigns a public IP -- REQUIRES a public subnet when true                                                                                              |
| environment                  | string      | -          | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags                         | map(string) | `{}`       | Extra tags applied to every created object                                                                                                                                                           |

## Outputs

| Name         | Description                                                                                   |
|--------------|------------------------------------------------------------------------------------------------|
| instance_id  | ID of the EC2 instance (i-...)                                                                  |
| instance_arn | ARN of the EC2 instance                                                                         |
| private_ip   | Private IP address of the instance inside its subnet                                            |
| public_ip    | Public IP address of the instance (empty string when associate_public_ip_address is false)      |
