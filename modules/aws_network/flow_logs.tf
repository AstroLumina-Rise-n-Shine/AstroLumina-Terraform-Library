# VPC Flow Logs (Trivy AWS-0178): capture every accepted and rejected flow
# for the VPC into CloudWatch Logs, so anomalous traffic is visible after
# the fact instead of guessed at. Gated by enable_flow_logs because
# CloudWatch Logs ingestion is billed on real AWS.

locals {
  # Same key-resolution pattern as the other modules: caller-supplied CMK
  # wins, otherwise create a rotating one unless the caller opted out.
  create_flow_logs_kms_key = var.enable_flow_logs && var.create_flow_logs_kms_key && var.flow_logs_kms_key_arn == null
  flow_logs_kms_key_arn    = var.flow_logs_kms_key_arn != null ? var.flow_logs_kms_key_arn : (local.create_flow_logs_kms_key ? aws_kms_key.flow_logs[0].arn : null)
}

# Customer-managed key for the flow-log group (Trivy AWS-0017). Rotation on,
# short deletion window for lab teardown. A CMK costs about $1/month on real
# AWS; set create_flow_logs_kms_key=false to use the CloudWatch-managed key.
resource "aws_kms_key" "flow_logs" {
  count = local.create_flow_logs_kms_key ? 1 : 0

  description             = "AstroLumina VPC Flow Logs key for ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_tags, { Name = "${var.name}-flow-logs" })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = local.flow_logs_kms_key_arn

  tags = local.common_tags
}

# Role the VPC Flow Logs service assumes to write into the log group. The
# inline policy is scoped to this one group; no other log group is reachable.
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs"
  role = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
      ]
      Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id               = aws_vpc.this.id
  traffic_type         = var.flow_logs_traffic_type
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow_logs[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn

  tags = merge(local.common_tags, { Name = "${var.name}-flow-logs" })

  depends_on = [aws_iam_role_policy.flow_logs]
}
