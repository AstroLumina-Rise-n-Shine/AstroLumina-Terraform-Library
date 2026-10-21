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

  # Encryption key resolution: a caller-supplied CMK always wins; otherwise
  # create a dedicated one unless the caller explicitly opted out. Keeping
  # the resolution in locals lets the table reference one expression while
  # the key resource stays count-gated.
  create_kms_key = var.create_kms_key && var.kms_key_arn == null
  kms_key_arn    = var.kms_key_arn != null ? var.kms_key_arn : (local.create_kms_key ? aws_kms_key.this[0].arn : null)
}

# Dedicated customer-managed key for table encryption (Trivy AWS-0025).
# Rotation is on and the deletion window is short so lab teardown does not
# leave a key scheduled for deletion for a month. A CMK costs about
# $1/month on real AWS; callers that cannot pay it set create_kms_key=false
# and keep the AWS-managed key instead.
resource "aws_kms_key" "this" {
  count = local.create_kms_key ? 1 : 0

  description             = "AstroLumina DynamoDB table key for ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, { Name = "${var.name}-dynamodb" })
}

# One DynamoDB table, optionally with a sort (range) key and TTL.
# Billing defaults to PAY_PER_REQUEST so a dormant learning table costs
# nothing; switch to PROVISIONED to practice capacity planning.
resource "aws_dynamodb_table" "this" {
  name = var.name

  hash_key = var.hash_key

  # The sort (range) key is optional: null means a hash-key-only table.
  range_key = var.range_key

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
  #
  # Note: inside a dynamic block the iterator is named after the block label
  # ("attribute"), not "each" -- "each" belongs to resource-level for_each.
  dynamic "attribute" {
    for_each = var.range_key != null ? [var.range_key] : []

    content {
      name = attribute.value
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

  # Continuous backups, restorable to any second in the last 35 days.
  # Costs nothing while the table is idle (Trivy AWS-0024).
  point_in_time_recovery {
    enabled = true
  }

  # Encrypt with the module-created (or caller-supplied) CMK instead of the
  # AWS-managed key, so key policy, grants and rotation stay under our
  # control. With create_kms_key=false and no kms_key_arn this block keeps
  # encryption on but falls back to the AWS-managed key.
  server_side_encryption {
    enabled     = true
    kms_key_arn = local.kms_key_arn
  }

  tags = merge(local.common_tags, { Name = var.name })
}
