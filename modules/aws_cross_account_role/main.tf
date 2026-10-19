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

# The cross-account role: it lives in THIS account but trusts the OTHER
# account's principals (identified by 12-digit trusted_account_id). Anyone
# authorized in the trusted account who calls sts:AssumeRole on this role's
# ARN receives exactly the permissions attached below and nothing more.
#
# The Condition block is only merged when external_id is set. An external ID
# is confused-deputy protection: without it, a third party that somehow sits
# between the trusted account and this role could still trigger the assume;
# with it, the trusting caller must also know the shared secret.
#
# Why a plain merge + ternary instead of "dynamic" heritage or duplicated
# statement bodies: the trust policy is a single JSON document inside one
# attribute -- assemble it as ordinary data and keep the difference between
# the two shapes one-line small.
resource "aws_iam_role" "this" {
  name                 = var.name
  max_session_duration = var.max_session_duration

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [merge(
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.trusted_account_id}:root" }
        Action    = "sts:AssumeRole"
      },
      # Confused-deputy protection, only attached when the caller chose one.
      var.external_id != null ? {
        Condition = { StringEquals = { "sts:ExternalId" = var.external_id } }
      } : {}
    )]
  })

  tags = local.common_tags
}

# Managed policies, one attachment per caller-supplied ARN. for_each over a
# set (instead of count) means reordering the list in a later apply
# creates/removes nothing -- sets are keyed by value.
#
# Permissions here are what the trusted account ends up borrowing, so keep
# the list as narrow as the task allows: the borrowed identity is only as
# dangerous as the policies you staple onto it.
resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# Inline policies, keyed by policy name => JSON document. Inline policies
# live inside the role itself; prefer managed policies for anything shared
# across roles.
resource "aws_iam_role_policy" "this" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.name
  policy = each.value
}
