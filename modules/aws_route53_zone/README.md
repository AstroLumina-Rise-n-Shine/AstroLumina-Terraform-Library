# aws_route53_zone

Creates a Route 53 hosted zone (public or private) plus optional plain DNS
records declared as a map. Use it whenever a stack needs its own domain:
the zone gives you authoritative name servers, and the `records` input
keeps simple A/TXT/MX-style entries in one table instead of one resource
block per record. Private zones attach to a VPC for internal-only names.

## Usage

```hcl
module "route53_zone" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_route53_zone?ref=main"

  name        = "lab.astrolumina.ro"
  environment = "lab"
  # ...the most important inputs...
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| name | string | — | Domain name of the hosted zone, e.g. lab.astrolumina.ro (record names build on top of it) |
| comment | string | "Managed by Terraform" | Free-form comment stored on the hosted zone |
| private_zone | bool | false | When true, create a private hosted zone that only answers inside the attached VPC instead of on the public internet |
| vpc_id | string | null | VPC the zone is associated with -- required when private_zone = true |
| vpc_region | string | null | Region of the VPC association -- optional when private_zone = true |
| records | map(object({ type = string, ttl = number, values = list(string) })) | `{}` | Map of extra DNS records: relative name (use '@' for the zone apex) => { type, ttl, values } |
| environment | string | — | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags | map(string) | `{}` | Extra tags applied to every created object |

## Outputs

| Name | Description |
|------|-------------|
| zone_id | Hosted zone ID (pass as zone_id to record or alias resources) |
| zone_name | Domain name of the hosted zone |
| name_servers | Authoritative name servers of the hosted zone (public zones: set these NS records at your registrar; private zones: only relevant inside the VPC) |
