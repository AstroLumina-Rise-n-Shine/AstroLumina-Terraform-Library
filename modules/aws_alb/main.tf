# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so stacks from different envs can never look identical.
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

# The edge: one ALB across at least two subnets. Deletion protection stays
# off (lab stacks must tear down cleanly). The listener defaults to secure:
# HTTPS on 443 with a caller-supplied certificate; emulators and labs
# without real certificates pass listener_protocol = "HTTP" explicitly.
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"

  # Reject malformed headers at the edge (request-smuggling defense;
  # Trivy AWS-0052).
  drop_invalid_header_fields = true

  security_groups = var.security_group_ids
  subnets         = var.subnet_ids

  enable_deletion_protection = false

  access_logs {
    enabled = true
    bucket  = var.access_logs_bucket
    prefix  = var.access_logs_prefix
  }

  tags = local.common_tags
}

# Where the ALB sends the traffic it accepts. target_type = "ip" fits
# Fargate/awsvpc tasks (each has its own ENI); use "instance" for EC2.
resource "aws_lb_target_group" "this" {
  name        = var.name
  port        = var.target_port
  protocol    = var.target_protocol
  vpc_id      = var.vpc_id
  target_type = var.target_type

  health_check {
    path = var.health_check_path
  }

  tags = local.common_tags
}

# The entry door: an HTTP listener that forwards everything to the target
# group. One listener per call; rules-based routing (paths, hosts, 404s)
# is left to whoever needs it -- this module keeps the common case boring.
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  # Certificates belong on TLS listeners only; sending one with plain
  # HTTP is an API error, so null both out for HTTP.
  certificate_arn = var.listener_protocol == "HTTPS" ? var.certificate_arn : null
  # nosemgrep: terraform.aws.security.insecure-load-balancer-tls-version.insecure-load-balancer-tls-version
  # The variable is validated to TLS 1.2+ and defaults to a TLS 1.3/1.2 policy.
  ssl_policy = var.listener_protocol == "HTTPS" ? var.ssl_policy : null

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = local.common_tags
}
