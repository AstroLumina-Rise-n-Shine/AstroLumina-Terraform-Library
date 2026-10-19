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

# The cluster itself: mostly a logical namespace for services and task
# definitions. Fargate needs no capacity providers to size or pay for --
# AWS launches the containers on demand. You never manage instances.
resource "aws_ecs_cluster" "this" {
  name = var.name

  # Container Insights: per-service CPU/memory/task metrics, included at
  # lab scale and the difference between "it is slow" and "no idea why"
  # (Trivy AWS-0034).
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

# IAM role assumed by the Fargate task agent: it pulls container images
# from ECR, writes container logs to CloudWatch, and fetches secrets.
# Without it the task hangs in PROVISIONING forever with no visible error,
# so every Fargate service needs one.
resource "aws_iam_role" "execution" {
  name = "${var.name}-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# The task definition is the "image + resources + port" recipe: cpu and
# memory are TASK-level values (string, like "256"/"512") that must match a
# Fargate size combination, not per-container docker-style numbers.
resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.cpu
  memory = var.memory

  execution_role_arn = aws_iam_role.execution.arn

  container_definitions = jsonencode([
    {
      name      = var.name
      image     = var.image
      essential = true

      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]

      # Environment variables come in as a plain map; the task definition
      # API wants a list of {name, value} objects, so we flip it here.
      environment = [
        for k, v in var.environment_variables : {
          name  = k
          value = v
        }
      ]
    }
  ])

  tags = local.common_tags
}

# The service keeps `desired_count` tasks running and replaces any that
# die. launch_type = "FARGATE" means serverless: no instances to own that
# the containers land on. The awsvpc network config gives every task its
# own ENI in the subnets you pass in with its own IP address.
resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  tags = local.common_tags
}
