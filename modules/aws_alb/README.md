# aws_alb: Application Load Balancer + target group + secure listener.

# One module call gives you the three pieces every ALB needs: the load
# balancer itself (spread over at least two subnets), a target group that
# decides how traffic reaches your app (EC2 by instance, Fargate tasks by
# `ip`, or Lambda), and the HTTP listener that forwards everything it
# accepts into that group. HTTPS/TLS is the default; local labs without a
# certificate can explicitly select HTTP.

## Usage

```hcl
module "alb_lab" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_alb?ref=main"

  name    = "lab-alb"
  vpc_id  = "vpc-xyz"

  subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  security_group_ids = ["sg-ccc"]
  access_logs_bucket = "lab-alb-access-logs"

  listener_protocol = "HTTP" # Local lab without an ACM certificate
  listener_port     = 80
  target_type       = "ip"   # Fargate targets: use aws ECS service; EC2 instances: "instance"
  health_check_path = "/"

  environment = "lab"
}
```

## Notes

- `target_type` pairs with your backend: `ip` for Fargate/awsvpc tasks,
  `instance` for EC2, `lambda` for functions. With `ip` targets register
  nothing here -- hand `target_group_arn` to the ECS service or attach
  targets where they are created.
- Access logs are enabled. `access_logs_bucket` must name an existing S3
  bucket in the ALB's region with a bucket policy that permits ELB log
  delivery.
- HTTPS/TLS is the default on port 443 and uses a TLS 1.2+ security policy.
  Supply `certificate_arn`; labs without a certificate can explicitly set
  `listener_protocol = "HTTP"` and `listener_port = 80`.
- On real AWS the ALB `name` must be <= 32 characters and is per-region
  unique; on Floci any DNS-safe name works.

## Inputs

| Name                 | Type         | Default | Description |
| -------------------- | ------------ | ------- | ----------- |
| `name`               | string       | n/a     | Name for the load balancer and target group |
| `vpc_id`             | string       | n/a     | VPC the target group lives in |
| `subnet_ids`         | list(string) | n/a     | At least two subnets (different AZs) the ALB attaches to, explicit IDs |
| `security_group_ids` | list(string) | n/a     | Security groups attached to the ALB (control who can reach the listener) |
| `internal`           | bool         | `true`  | Internal load balancer (true for VPC-only ingress, e.g. behind a VPN) |
| `access_logs_bucket` | string       | n/a     | Existing same-region S3 bucket configured to accept ELB access logs |
| `access_logs_prefix` | string       | `null`  | Optional prefix for ALB access logs |
| `listener_port`      | number       | `443`   | Port the ALB listener accepts traffic on |
| `listener_protocol`  | string       | `"HTTPS"` | Listener protocol; use `HTTP` only for labs without a certificate |
| `certificate_arn`    | string       | `null`  | ACM/imported certificate ARN required for HTTPS |
| `ssl_policy`         | string       | TLS 1.3/1.2 policy | TLS policy for HTTPS; validation rejects policies older than TLS 1.2 |
| `target_port`        | number       | `80`    | Port targets receive traffic on |
| `target_protocol`    | string       | `"HTTP"`| Protocol used to talk to targets (e.g. HTTP, TCP) |
| `target_type`        | string       | `"ip"`  | Kind of target: instance, ip or lambda (validated) |
| `health_check_path`  | string       | `"/"`   | HTTP path the ALB requests to decide whether a target is healthy |
| `tags`               | map(string)  | `{}`    | Extra tags applied to every created object |
| `environment`        | string       | n/a     | Deployment environment this stack belongs to; always stamped as the `Environment` tag |

## Outputs

| Name               | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `alb_arn`          | ARN of the Application Load Balancer                                    |
| `alb_dns_name`     | DNS name to point traffic at (ALBs have no fixed IP)                    |
| `alb_zone_id`      | Route 53 hosted-zone ID of the ALB, needed for alias DNS records        |
| `target_group_arn` | ARN of the target group (register targets here or hand it to an ECS service) |
| `listener_arn`     | ARN of the forward listener                                             |
