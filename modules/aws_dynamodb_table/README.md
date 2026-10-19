# aws_dynamodb_table

Creates a DynamoDB table with an optional sort (range) key and an optional
TTL attribute. Billing defaults to PAY_PER_REQUEST so an idle learning
table costs nothing, and key validation in variables.tf catches typos
before they reach the API. Encryption uses a dedicated customer-managed KMS
key with rotation by default (Trivy AWS-0025); bring your own key with
`kms_key_arn` or set `create_kms_key = false` to keep the AWS-managed key.
It is the simplest persistence building block the library offers — pair it
with aws_lambda_function for serverless demos.

## Usage

```hcl
module "sessions" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_dynamodb_table?ref=main"

  name        = "lab-sessions"
  environment = "lab"

  hash_key      = "id"
  hash_key_type = "S"
  range_key     = null
  ttl_attribute = "expires_at"
}
```

## Inputs

| Name            | Type        | Default          | Description                                                                                                                            |
|-----------------|-------------|------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| name            | string      | -                | Table name (unique per account/region)                                                                                                  |
| hash_key        | string      | `id`             | Attribute holding the partition (hash) key                                                                                              |
| hash_key_type   | string      | `S`              | Type of the hash-key attribute: S (string), N (number) or B (binary)                                                                     |
| range_key       | string      | `null`           | Optional attribute holding the sort (range) key; leave null for hash-key-only tables                                                     |
| range_key_type  | string      | `S`              | Type of the range-key attribute: S (string), N (number) or B (binary)                                                                    |
| billing_mode    | string      | `PAY_PER_REQUEST`| PAY_PER_REQUEST (on-demand, pay per call) or PROVISIONED (fixed capacity)                                                                |
| read_capacity   | number      | `5`              | Read capacity units -- ignored (on real AWS) unless billing_mode is PROVISIONED                                                          |
| write_capacity  | number      | `5`              | Write capacity units -- ignored (on real AWS) unless billing_mode is PROVISIONED                                                         |
| ttl_attribute   | string      | `null`           | Optional attribute (e.g. "expires_at") holding epoch seconds; when set, TTL deletion is enabled on it                                    |
| create_kms_key  | bool        | `true`           | Create a dedicated customer-managed KMS key (rotation on) for table encryption when `kms_key_arn` is null. A CMK costs about $1/month on real AWS; set false to keep the AWS-managed key (reintroduces Trivy AWS-0025) |
| kms_key_arn     | string      | `null`           | Existing customer-managed KMS key ARN to use instead of creating one                                                                    |
| environment     | string      | -                | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags            | map(string) | `{}`             | Extra tags applied to every created object                                                                                              |

## Outputs

| Name        | Description                                                     |
|-------------|-----------------------------------------------------------------|
| table_name  | Name of the created DynamoDB table                               |
| table_arn   | ARN of the table -- useful for IAM policy references             |
| table_id    | ID of the table (table name, as DynamoDB reports it)             |
| kms_key_arn | ARN of the CMK encrypting the table (null when opted out and no key supplied) |

## Floci note

With `create_kms_key = true` (the default) the provider also needs a KMS
endpoint. Add `kms = "http://localhost:4566"` to the provider `endpoints`
block when running against Floci.
