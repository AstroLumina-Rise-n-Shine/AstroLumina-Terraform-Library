# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so stacks from different envs can never look identical.
locals {
  common_tags = merge(
    {
      Project   = "AstroLumina"
      ManagedBy = "terraform"
    },
    var.tags,
    {
      Environment = var.environment
    }
  )
}

# The customer gateway is the on-prem side of the tunnel: the public IP of
# the router/firewall that terminates the VPN, plus its BGP ASN for
# dynamic routing (unused with static_routes_only, but the object still
# needs an ASN).
resource "aws_customer_gateway" "this" {
  bgp_asn    = var.bgp_asn
  ip_address = var.customer_gateway_ip
  type       = "ipsec.1"

  tags = local.common_tags
}

# The VPN gateway: the AWS-side endpoint of the tunnels, attached to a VPC
# so traffic can flow into it.
resource "aws_vpn_gateway" "this" {
  tags = local.common_tags
}

resource "aws_vpn_gateway_attachment" "this" {
  vpc_id         = var.vpc_id
  vpn_gateway_id = aws_vpn_gateway.this.id
}

# The actual IPsec connection. AWS/Floci brings up TWO tunnels for
# redundancy (see tunnel1/tunnel2 outputs). With static_routes_only = true
# you declare the on-prem CIDRs yourself below; with BGP the routes would
# be learned dynamically instead.
resource "aws_vpn_connection" "this" {
  vpn_gateway_id      = aws_vpn_gateway.this.id
  customer_gateway_id = aws_customer_gateway.this.id
  type                = "ipsec.1"

  static_routes_only = var.static_routes_only

  tags = local.common_tags
}

# Static routes pointing at the on-prem CIDRs, so instances "know" that
# traffic for the home network must flow through the VPN connection.
resource "aws_vpn_connection_route" "this" {
  for_each = toset(var.destination_cidrs)

  destination_cidr_block = each.value
  vpn_connection_id      = aws_vpn_connection.this.id
}

# Optional propagation: push the VPN routes into the caller's route tables
# so subnets using them actually route via the VPN gateway.
resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = toset(var.route_table_ids)

  vpn_gateway_id = aws_vpn_gateway.this.id
  route_table_id = each.value
}
