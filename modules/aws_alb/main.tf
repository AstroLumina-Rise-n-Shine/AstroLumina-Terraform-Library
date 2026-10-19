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

# The edge: one ALB across at least two subnets. Fields left off here are
# deliberate: deletion protection off (lab stacks must tear down cleanly)
# and TLS off (plain HTTP listener -- put TLS termination on the caller's
# side or extend this module when needed).
resource "aws_lb" "this" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"

  security_groups = var.security_group_ids
  subnets         = var.subnet_ids

  enable_deletion_protection = false

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
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = local.common_tags
}
