# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so users from different envs can never look identical.
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

# The IAM user itself -- a named identity for humans or machine access.
# On real AWS this would typically live behind SSO or OIDC federation; a
# static user with a programmatic key is deliberately the learning-friendly
# shape (see the access key resource below).
resource "aws_iam_user" "this" {
  name = var.name

  tags = local.common_tags
}

# Managed policies, one attachment per caller-supplied ARN. for_each over a
# set (instead of count) means reordering the list in a later apply
# creates/removes nothing -- sets are keyed by value.
resource "aws_iam_user_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  user       = aws_iam_user.this.name
  policy_arn = each.value
}

# Inline policies, keyed by policy name => JSON document. Inline policies
# live inside the user itself; prefer managed policies for anything shared
# across multiple identities.
resource "aws_iam_user_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  user   = aws_iam_user.this.name
  policy = each.value
}

# Optional programmatic access key (access key id + secret). Off by default:
# least privilege first -- create long-lived credentials only when a lab or
# demo genuinely needs them, and treat the secret as a sensitive value never
# printed to logs or committed to git. On real AWS prefer roles or STS
# whenever you can.
resource "aws_iam_access_key" "this" {
  count = var.create_access_key ? 1 : 0

  user = aws_iam_user.this.name
}
