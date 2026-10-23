# aws_elasticache_redis: a single-node Redis cache, encrypted and private by default.

# One module call creates the cache subnet group, an optional dedicated
# security group, an optional parameter group, and a single-node Redis
# replication group. ElastiCache handles provisioning and patching; you
# decide where the cache lives, how big it is, and who may reach port 6379.
# There is deliberately NO Kubernetes object in this module: Redis is a
# plain AWS cache consumed by applications (the AWS lab wires it up later,
# after the Library tag is cut).

## Usage

```hcl
module "redis_lab" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_elasticache_redis?ref=main"

  name        = "lab-redis"
  subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  environment = "lab"

  # The module creates a security group in this VPC; it starts closed.
  vpc_id = "vpc-12345678"

  # Preferred: let the app security group in, no CIDR arithmetic.
  allowed_security_group_ids = ["sg-app"]

  # Or CIDRs inside the VPC (never 0.0.0.0/0).
  allowed_cidr_blocks = ["10.0.0.0/16"]
}
```

Bring your own key for at-rest encryption:

```hcl
module "redis_lab" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_elasticache_redis?ref=main"

  name        = "lab-redis"
  subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  environment = "lab"
  vpc_id      = "vpc-12345678"

  kms_key_id = "arn:aws:kms:eu-west-1:123456789012:key/00000000-0000-0000-0000-000000000000"
}
```

## Connectivity

- `create_security_group = true` (default) creates `${name}-redis` **with no
  ingress rules**. You must opt in with `allowed_security_group_ids` or
  `allowed_cidr_blocks`; a cache that is unreachable by accident is safer
  than one that is reachable by accident.
- When `create_security_group = true`, `vpc_id` is required. Passing it when
  the group is not created is harmless.
- `security_group_ids` and the module-created group are **merged**, never
  replaced: existing callers keep their groups attached.
- No egress rules are defined on the created group -- the cache answers
  connections and never dials out, so outbound traffic stays denied.

## Security defaults

- At-rest encryption is on (`at_rest_encryption_enabled = true`) with the
  AWS-managed key unless you supply `kms_key_id` (Trivy AWS-0100).
- In-transit encryption is on (`transit_encryption_enabled = true`), so
  clients must use `rediss://` / `tls` in their connection settings
  (Trivy AWS-0105).
- `auth_token` is optional, sensitive and has no default. It requires
  transit encryption and must be 16-128 characters; pass it via tfvars or
  `-var`, never in committed code. State still holds it in plaintext, so
  keep state remote and locked down (or use a secrets manager in
  production).
- Daily snapshots keep 1 day by default (`snapshot_retention_limit = 1`,
  Trivy AWS-0175). `0` disables backups.

## Notes

- The resource is an `aws_elasticache_replication_group` with
  `num_cache_clusters = 1`, not a bare cache cluster: the replication-group
  API is the current one, exposes primary/reader endpoints, and can grow
  into a real replica set later without changing resource type. Automatic
  failover and Multi-AZ stay off because both need at least two nodes.
- `parameter_group_family` must match `engine_version` (`redis7` for 7.x).
  Set `create_parameter_group = false` to let AWS pick the default group.
- No Kubernetes resources, manifests or Helm charts are shipped here.

## Inputs

| Name                           | Type         | Default            | Description |
| ------------------------------ | ------------ | ------------------ | ----------- |
| `name`                         | string       | n/a                | Replication group identifier (also prefixes subnet/parameter/security group names) |
| `subnet_ids`                   | list(string) | n/a                | At least two subnets (different AZs ideal) for the cache subnet group, explicit IDs |
| `vpc_id`                       | string       | `null`             | VPC for the module-created security group; required when `create_security_group = true` |
| `security_group_ids`           | list(string) | `[]`               | Existing security groups kept alongside the module-created one |
| `create_security_group`        | bool         | `true`             | Create a dedicated, initially closed security group |
| `allowed_cidr_blocks`          | list(string) | `[]`               | CIDRs allowed to reach the Redis port (keep inside the VPC) |
| `allowed_security_group_ids`   | list(string) | `[]`               | Peer security groups allowed to reach the Redis port |
| `node_type`                    | string       | `"cache.t3.micro"` | ElastiCache node type |
| `engine_version`               | string       | `"7.1"`            | Redis engine version |
| `parameter_group_family`       | string       | `"redis7"`         | Parameter group family matching `engine_version` |
| `create_parameter_group`       | bool         | `true`             | Create a parameter group pinned to `parameter_group_family` |
| `port`                         | number       | `6379`             | Port the cache listens on |
| `at_rest_encryption_enabled`   | bool         | `true`             | Encrypt cache storage at rest |
| `kms_key_id`                   | string       | `null`             | Optional customer-managed KMS key for at-rest encryption |
| `transit_encryption_enabled`   | bool         | `true`             | Encrypt client connections with TLS |
| `auth_token`                   | string       | `null`             | Optional sensitive Redis AUTH token (16-128 chars, requires TLS) |
| `snapshot_retention_limit`     | number       | `1`                | Days of daily snapshots kept (0 disables) |
| `tags`                         | map(string)  | `{}`               | Extra tags applied to every created object |
| `environment`                  | string       | n/a                | Deployment environment; always stamped as the `Environment` tag |

## Outputs

| Name                             | Description |
| -------------------------------- | ----------- |
| `id`                             | Identifier of the Redis replication group |
| `arn`                            | ARN of the Redis replication group |
| `primary_endpoint_address`       | Hostname clients write to (primary endpoint) |
| `reader_endpoint_address`        | Hostname for read-only clients (reader endpoint) |
| `port`                           | Port the cache listens on |
| `security_group_id`              | Module-created security group ID (null when `create_security_group = false`) |
| `configuration_endpoint_address` | Cluster-mode configuration endpoint (null: cluster mode is always disabled here) |
