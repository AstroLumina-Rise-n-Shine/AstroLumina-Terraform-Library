# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so roles from different envs can never look identical.
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

# The IAM role itself. The trust policy (WHO may assume the role) is either a
# fully custom JSON document from the caller, or -- by far the common case --
# a generated service trust policy: "let <assume_role_service> (e.g. EC2)
# assume this role". Starting from the service default keeps lab setups
# one-variable simple while the JSON escape hatch covers every other shape.
resource "aws_iam_role" "this" {
  name = var.name

  assume_role_policy = var.assume_role_policy_json != null ? var.assume_role_policy_json : jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = var.assume_role_service }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

# Managed policies, one attachment per caller-supplied ARN. Using for_each
# over a set (instead of count) means reordering the list in a later apply
# creates/removes nothing -- sets are keyed by value.
resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Inline policies, keyed by policy name => JSON document. Inline policies
# live inside the role itself (a role has at most a handful); prefer managed
# policies for anything shared across roles.
resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}
