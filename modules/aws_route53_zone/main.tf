# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so zones from different envs can never look identical.
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

# The hosted zone: AWS's authoritative DNS database for the domain var.name.
# Public zones answer from Route 53's global name servers; private zones
# only answer inside the VPC they are attached to (service discovery,
# internal names). The vpc block is therefore dynamic: it exists only when
# private_zone is true, and vpc_id is required in that case.
resource "aws_route53_zone" "this" {
  name    = var.name
  comment = var.comment

  dynamic "vpc" {
    for_each = var.private_zone ? [1] : []

    content {
      vpc_id     = var.vpc_id
      vpc_region = var.vpc_region
    }
  }

  tags = local.common_tags
}

# Extra records: the map key is the RELATIVE record name (e.g. "www"),
# with "@" as the conventional alias for the zone apex. Records that are
# plain DNS names (no alias targets) keep the simple ttl + values shape,
# which covers A/AAAA/TXT/MX/CNAME-style lab records.
resource "aws_route53_record" "this" {
  for_each = var.records

  zone_id = aws_route53_zone.this.id
  name    = each.key == "@" ? var.name : "${each.key}.${var.name}"
  type    = each.value.type
  ttl     = each.value.ttl
  records = each.value.values
}
