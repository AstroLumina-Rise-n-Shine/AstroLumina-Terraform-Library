# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so tables from different envs can never look identical.
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

# One DynamoDB table, optionally with a sort (range) key and TTL.
# Billing defaults to PAY_PER_REQUEST so a dormant learning table costs
# nothing; switch to PROVISIONED to practice capacity planning.
resource "aws_dynamodb_table" "this" {
  name = var.name

  hash_key = var.hash_key

  billing_mode = var.billing_mode

  # Capacity units are only meaningful (and only accepted) with PROVISIONED
  # billing -- pass null under on-demand pricing instead of misleading 5s.
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # The hash-key attribute is mandatory, so it is declared statically.
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  # The range key is optional: declare it dynamically only when the caller
  # named one. The API rejects an empty attribute for the sort key.
  dynamic "attribute" {
    for_each = var.range_key != null ? [var.range_key] : []
    content {
      name = each.value
      type = var.range_key_type
    }
  }

  # TTL lets DynamoDB silently delete expired items. Enabled only when the
  # caller names an attribute (e.g. "expires_at") to hold the epoch seconds.
  dynamic "ttl" {
    for_each = var.ttl_attribute != null ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute
    }
  }

  tags = merge(local.common_tags, { Name = var.name })
}
