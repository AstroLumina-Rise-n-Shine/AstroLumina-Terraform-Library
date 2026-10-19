# aws_ecs_fargate: serverless containers -- ECS cluster, task definition and service in one call.

# One module call gives you a running Fargate workload: a cluster to live
# in, an execution IAM role so the task can pull images and write logs, a
# task definition (image + cpu/memory + port), and a service that keeps
# `desired_count` copies alive. No EC2 instances to patch, size or pay for
# while idle. Point an ALB target group at the output service (targets of
# type `ip`) to put it behind a load balancer.

## Usage

```hcl
module "ecs_web" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_ecs_fargate?ref=main"

  name    = "lab-ecs-web"
  image   = "nginx:alpine"

  cpu           = "256"
  memory        = "512"
  desired_count = 1

  subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  security_group_ids = ["sg-ccc"]
  container_port     = 80

  environment = "lab"
}
```

## Notes

- `cpu` and `memory` are task-level strings because the Fargate API expects
  them that way; they must form a valid Fargate size (e.g. 256/512,
  512/1024, 1024/2048). Only one container per task definition is created.
- Each task gets its own ENI (`awsvpc` network mode); when the subnets are
  private with no NAT, keep `assign_public_ip = true` or image pulls from
  ECR fail.

## Inputs

| Name                   | Type         | Default | Description |
| ---------------------- | ------------ | ------- | ----------- |
| `name`                 | string       | n/a     | Name used for the cluster, task definition family, service and execution role |
| `image`                | string       | n/a     | Container image to run, e.g. nginx:alpine |
| `cpu`                  | string       | `"256"` | Task-level CPU units as a string (Fargate valid combos: 256/512, 512/1024, ...) |
| `memory`               | string       | `"512"` | Task-level memory in MiB as a string (must pair with cpu per Fargate size table) |
| `desired_count`        | number       | `1`     | Number of tasks the service keeps running |
| `subnet_ids`           | list(string) | n/a     | Subnets the task ENIs live in (explicit IDs, no data-source lookup) |
| `security_group_ids`   | list(string) | `[]`    | Security groups attached to the task ENIs |
| `container_port`       | number       | `80`    | Port the container listens on (published inside the task network) |
| `assign_public_ip`     | bool         | `true`  | Give each task ENI a public IP (ENABLED needed for image pulls from private subnets with no NAT) |
| `environment_variables`| map(string)  | `{}`    | Environment variables injected into the container |
| `tags`                 | map(string)  | `{}`    | Extra tags applied to every created object |
| `environment`          | string       | n/a     | Deployment environment this stack belongs to; always stamped as the `Environment` tag |

## Outputs

| Name                 | Description                                         |
| -------------------- | --------------------------------------------------- |
| `cluster_arn`        | ARN of the ECS cluster                              |
| `cluster_name`       | Name of the ECS cluster                             |
| `service_name`       | Name of the ECS service                             |
| `task_definition_arn`| ARN of the task definition revision the service runs |
