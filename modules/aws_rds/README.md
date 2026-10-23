# aws_rds: a managed database instance inside a dedicated DB subnet group.

# One module call creates the DB subnet group (where in the VPC RDS may
# place instances) and the RDS instance itself: engine, class, storage,
# credentials and networking in one place. RDS handles the boring parts
# (provisioning, patching, restart-on-crash) so you only decide where it
# lives, how big it is, and who may connect. Pass the password via tfvars
# or -var, never as committed code.

## Usage

```hcl
module "rds_lab" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_rds?ref=main"

  name    = "lab-db"
  engine  = "postgres"

  instance_class     = "db.t3.micro"
  subnet_ids         = ["subnet-aaa", "subnet-bbb"]
  security_group_ids = ["sg-ccc"]

  password = "change-me-via-tfvars" # use a dedicated tfvars file outside git

  environment = "lab"
}
```

## Notes

- `password` is required and sensitive -- terraform keeps it out of plan
  output, but state is still plaintext, so keep state remote and locked
  down; in production switch to a secrets manager instead.
- `skip_final_snapshot = true` by default so destroying the lab stack does
  not leave a snapshot behind (cost + blocker on teardown).
- PostgreSQL logs are exported to CloudWatch by default. Other engines
  require `enabled_cloudwatch_logs_exports` to be set to their supported
  log types.
- Performance Insights is encrypted with a dedicated customer-managed KMS
  key with rotation by default (Trivy AWS-0078). Bring your own key with
  `kms_key_arn`, or set `create_kms_key = false` to keep the AWS-managed
  key. No key is created when `performance_insights_enabled = false`.
- When running against Floci with the default key creation, add
  `kms = "http://localhost:4566"` to the provider `endpoints` block.

## Inputs

| Name                  | Type         | Default       | Description |
| --------------------- | ------------ | ------------- | ----------- |
| `name`                | string       | n/a           | DB instance identifier (also prefixes the subnet group name; also the Name tag) |
| `engine`              | string       | `"postgres"`  | Database engine (e.g. postgres, mysql) |
| `engine_version`      | string       | `null`        | Engine version; null lets AWS/Floci pick the default for the engine |
| `instance_class`      | string       | `"db.t3.micro"`| DB instance class (the smallest burstable one is fine for learning) |
| `allocated_storage`   | number       | `20`          | Storage size in gibibytes |
| `db_name`             | string       | `"astrolumina"`| Initial database name created inside the instance |
| `username`            | string       | `"astrolumina"`| Master username for the instance |
| `password`            | string       | n/a           | Master password (sensitive). Learning-only: pass via tfvars/CLI, never commit it to git |
| `port`                | number       | `5432`        | Port the database listens on (5432 for postgres, 3306 for mysql) |
| `subnet_ids`          | list(string) | n/a           | At least two subnets (different AZs ideal) for the DB subnet group, explicit IDs |
| `security_group_ids`  | list(string) | `[]`          | Security groups controlling who can reach the database port |
| `publicly_accessible` | bool         | `false`       | Give the instance a public IP (keep false; reach it inside the VPC) |
| `storage_encrypted`   | bool         | `true`        | Encrypt storage at rest with an AWS-managed key |
| `enabled_cloudwatch_logs_exports` | list(string) | `null` (PostgreSQL uses `["postgresql"]`) | Engine-compatible database logs exported to CloudWatch; required for non-PostgreSQL engines |
| `backup_retention_period` | number   | `7`           | Days of automatic backups kept (0 disables) |
| `iam_database_authentication_enabled` | bool | `true` | Let apps authenticate with short-lived IAM tokens instead of the master password |
| `deletion_protection` | bool         | `true`        | Block accidental deletion of the instance; lab stacks set `false` so destroy stays one command |
| `performance_insights_enabled` | bool | `true`      | Enable Performance Insights (query-level monitoring; the 7-day retention is free tier) |
| `performance_insights_retention_period` | number | `7` | Days of Performance Insights data kept |
| `create_kms_key`      | bool         | `true`        | Create a dedicated customer-managed KMS key (rotation on) for Performance Insights when `kms_key_arn` is null and PI is enabled. A CMK costs about $1/month on real AWS |
| `kms_key_arn`         | string       | `null`        | Existing customer-managed KMS key ARN for Performance Insights encryption |
| `skip_final_snapshot` | bool         | `true`        | Skip the final snapshot on destroy (fast, cheap teardown) |
| `tags`                | map(string)  | `{}`          | Extra tags applied to every created object |
| `environment`         | string       | n/a           | Deployment environment this stack belongs to; always stamped as the `Environment` tag |

## Outputs

| Name                | Description                                        |
| ------------------- | -------------------------------------------------- |
| `db_instance_id`    | Identifier of the RDS instance                     |
| `db_instance_arn`   | ARN of the RDS instance                            |
| `db_instance_address`| Connection hostname (endpoint) of the RDS instance |
| `db_instance_port`  | Port the database listens on                       |
| `db_name`           | Name of the initial database created inside the instance |
| `performance_insights_kms_key_arn` | ARN of the CMK encrypting Performance Insights data (null when PI is off or key creation was opted out) |
