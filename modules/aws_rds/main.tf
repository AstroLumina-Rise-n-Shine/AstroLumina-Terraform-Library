# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so databases from different envs can never look identical.
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
resource "aws_db_instance" "this" {
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

  publicly_accessible = var.publicly_accessible
  storage_encrypted   = var.storage_encrypted

  # No final snapshot by default: for a lab database the snapshot is a
  # leftover cost and a teardown blocker, not a safety net.
  skip_final_snapshot = var.skip_final_snapshot

  tags = local.common_tags
}
