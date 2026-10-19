# aws_vpn: site-to-site VPN building blocks -- gateway, customer gateway, tunnels and routes.

# One module call wires up the classic hybrid-cloud story: an on-prem
# firewall (customer gateway identified by its public IP), an AWS-side VPN
# gateway attached to your VPC, and an IPsec connection that brings up TWO
# redundant tunnels between them. With `static_routes_only = true` (the
# learning-friendly default) you list the on-prem CIDRs yourself; the
# optional route propagation pushes those routes into your VPC route
# tables so traffic actually flows through the VPN.

## Usage

```hcl
module "vpn_lab" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_vpn?ref=main"

  name    = "lab-vpn"
  vpc_id  = "vpc-xyz"

  customer_gateway_ip = "203.0.113.10"
  destination_cidrs   = ["10.0.0.0/16"] # on-prem network(s)
  route_table_ids     = ["rtb-abc"]     # optional propagation

  environment = "lab"
}
```

## Notes

- Bring-up is two-sided: after apply, configure the on-prem device with the
  `tunnel1_address`/`tunnel2_address` outputs (plus shared keys/side
  settings) -- the tunnel is only UP once both ends talk.
- `bgp_asn` is kept as a string because the API accepts it that way; the
  object requires an ASN even when you route statically.
- On Floci there is no real on-prem device to configure, so the tunnel
  object is validated/created without live connectivity.

## Inputs

| Name                  | Type         | Default         | Description |
| --------------------- | ------------ | --------------- | ----------- |
| `name`                | string       | n/a             | Name prefix for the VPN objects (also the Name tags) |
| `vpc_id`              | string       | n/a             | VPC the VPN gateway attaches to |
| `customer_gateway_ip` | string       | n/a             | Public IP of the on-prem router/firewall terminating the VPN |
| `bgp_asn`             | string       | `"65000"`       | BGP ASN of the customer gateway (always required, even with static routes) |
| `static_routes_only`  | bool         | `true`          | Declare on-prem destination CIDRs manually instead of learning them via BGP |
| `destination_cidrs`   | list(string) | `["10.0.0.0/16"]`| On-prem CIDRs routed through the VPN (only used with static routes) |
| `route_table_ids`     | list(string) | `[]`            | Optional route tables the VPN routes are propagated into |
| `tags`                | map(string)  | `{}`            | Extra tags applied to every created object |
| `environment`         | string       | n/a             | Deployment environment this stack belongs to; always stamped as the `Environment` tag |

## Outputs

| Name                 | Description                                                          |
| -------------------- | -------------------------------------------------------------------- |
| `vpn_connection_id`  | ID of the IPsec VPN connection                                       |
| `vpn_gateway_id`     | ID of the VPN gateway attached to the VPC                            |
| `customer_gateway_id`| ID of the customer gateway (the on-prem side object)                 |
| `tunnel1_address`    | Public IP of the first VPN tunnel endpoint (configure it on-prem)    |
| `tunnel2_address`    | Public IP of the second (redundant) VPN tunnel endpoint              |
