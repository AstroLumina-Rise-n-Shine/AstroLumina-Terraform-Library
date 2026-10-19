# VPC Flow Logs (Trivy AWS-0178): capture every accepted and rejected flow
# for the VPC into CloudWatch Logs, so anomalous traffic is visible after
# the fact instead of guessed at. Gated by enable_flow_logs because
# CloudWatch Logs ingestion is billed on real AWS.

locals {
  # Same key-resolution pattern as the other modules: caller-supplied CMK
  # wins, otherwise create a rotating one unless the caller opted out.
  create_flow_logs_kms_key = var.enable_flow_logs && var.create_flow_logs_kms_key && var.flow_logs_kms_key_arn == null
  flow_logs_kms_key_arn    = var.flow_logs_kms_key_arn != null ? var.flow_logs_kms_key_arn : (local.create_flow_logs_kms_key ? aws_kms_key.flow_logs[0].arn : null)

  # The VPC ARN carries the partition, region and account, so the role trust
  # conditions below need no extra data source (and no STS call).
  vpc_arn_parts = split(":", aws_vpc.this.arn)
  account_id    = local.vpc_arn_parts[4]

  # AWS evaluates the vpc-flow-logs.amazonaws.com sts:AssumeRole call against
  # the *flow-log* ARN, not the VPC ARN:
  # https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-iam-role.html
  # The flow-log ID does not exist until aws_flow_log.this is created, and
  # referencing aws_flow_log.this.arn here would create a Terraform dependency
  # cycle (the flow log needs this role's ARN). AWS documents wildcarding the
  # flow-log ID for exactly this case; partition, region, account and the
  # vpc-flow-log resource type stay pinned.
  flow_log_source_arn = "arn:${local.vpc_arn_parts[1]}:ec2:${local.vpc_arn_parts[3]}:${local.account_id}:vpc-flow-log/*"
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
# trust policy pins the account and the flow-log resource type (confused
# deputy), and the inline policy writes to this one group only.
resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name = "${var.name}-flow-logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = local.flow_log_source_arn }
      }
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
    Statement = [
      {
        Sid    = "WriteFlowLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.flow_logs[0].arn}:*"
      },
      {
        # CloudWatch Logs describes are account-level list operations:
        # DescribeLogGroups takes no resource type at all, so it cannot be
        # scoped to one log group. AWS's own flow-log role policy grants
        # these two actions on "*".
        Sid    = "DescribeFlowLogDestinations"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Resource = "*"
      },
    ]
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
