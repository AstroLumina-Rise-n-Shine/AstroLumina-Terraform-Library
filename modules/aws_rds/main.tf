# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so databases from different envs can never look identical.
locals {
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports == null ? ["postgresql"] : var.enabled_cloudwatch_logs_exports

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

  # Performance Insights key resolution: caller-supplied CMK wins, otherwise
  # create a dedicated one when PI is enabled and the caller did not opt out.
  # No key is created when PI is off (the key would be unused and billed).
  create_pi_kms_key = var.performance_insights_enabled && var.create_kms_key && var.kms_key_arn == null
  pi_kms_key_arn    = var.performance_insights_enabled ? (var.kms_key_arn != null ? var.kms_key_arn : (local.create_pi_kms_key ? aws_kms_key.this[0].arn : null)) : null
}

# Dedicated customer-managed key for Performance Insights (Trivy AWS-0078).
# Rotation is on; the short deletion window keeps lab teardown cheap. A CMK
# costs about $1/month on real AWS, so create_kms_key can be set to false.
resource "aws_kms_key" "this" {
  count = local.create_pi_kms_key ? 1 : 0

  description             = "AstroLumina RDS Performance Insights key for ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, { Name = "${var.name}-performance-insights" })
}

# A DB subnet group is how RDS learns where it is allowed to live: you hand
# it subnets (ideally at least two, in two AZs, for Multi-AZ) instead of
# placing the instance on one subnet yourself.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnets"
  subnet_ids = var.subnet_ids

  tags = local.common_tags
}

# The database instance itself. Defaults are deliberately learning-friendly:
# smallest instance class, 20 GB, final snapshot skipped so teardown is fast
# and cheap. Encryption at rest is ON by default -- flipping it off saves
# nothing on a lab stack and losing the habit is expensive.
# CloudWatch exports are configured via the engine-aware module input below.
resource "aws_db_instance" "this" { # nosemgrep: terraform.aws.security.aws-db-instance-no-logging.aws-db-instance-no-logging
  identifier = var.name

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password
  port     = var.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids

  publicly_accessible             = var.publicly_accessible
  storage_encrypted               = var.storage_encrypted
  enabled_cloudwatch_logs_exports = local.enabled_cloudwatch_logs_exports

  # Performance Insights: query-level history turns "the database is slow"
  # into "this query is slow". The default 7-day retention sits in the free
  # tier (Trivy AWS-0133).
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period

  # Encrypt PI data with the module-created (or caller-supplied) CMK instead
  # of the AWS-managed key (Trivy AWS-0078). Null when PI is disabled:
  # RDS rejects a key id on a DB instance with PI turned off.
  performance_insights_kms_key_id = local.pi_kms_key_arn

  # Continuous backups: 7 days by default -- enough to recover from an
  # "oops", short enough to stay cheap (Trivy AWS-0077).
  backup_retention_period = var.backup_retention_period

  # Token-based access for applications instead of long-lived passwords
  # (Trivy AWS-0176).
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # Refuse deletion while true; labs flip it off so teardown is one command
  # (Trivy AWS-0177).
  deletion_protection = var.deletion_protection

  # No final snapshot by default: for a lab database the snapshot is a
  # leftover cost and a teardown blocker, not a safety net.
  skip_final_snapshot = var.skip_final_snapshot

  tags = local.common_tags
}
