# aws_lambda_function

Creates a single Lambda function from a local zip file, wired to an
execution role the caller provides. It has no IAM trappings of its own —
that is deliberate: this module is just the "function" half of a
serverless pair, and the IAM role is the caller's design decision. Pair it
with an IAM role module and a DynamoDB table for the classic demo stack.

## Usage

```hcl
module "greet" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_lambda_function?ref=main"

  name        = "lab-greeter"
  environment = "lab"

  filename  = "${path.module}/../../lambdas/greeter.zip"
  role_arn  = module.role.role_arn
  handler   = "index.handler"
  runtime   = "python3.12"

  environment_variables = {
    TABLE = module.sessions.table_name
  }
}
```

Lambda encrypts environment variables with an AWS-managed KMS key by
default. Set `environment_kms_key_arn` to use a customer-managed key; the
function's execution role must have permission to decrypt with that key.

## Inputs

| Name                  | Type        | Default        | Description                                                                                                                                                                                         |
|-----------------------|-------------|----------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                  | string      | -              | Function name (also the Name tag)                                                                                                                                                                    |
| filename              | string      | -              | Path to the deployment zip file                                                                                                                                                                      |
| source_code_hash      | string      | `null`         | Hash of the zip contents -- change it so Terraform re-uploads the code (e.g. filebase64sha256(file(var.filename)))                                                                                     |
| handler               | string      | `index.handler`| Entry-point of the function code (file.function)                                                                                                                                                      |
| runtime               | string      | `python3.12`   | Lambda runtime identifier                                                                                                                                                                             |
| role_arn              | string      | -              | ARN of the IAM execution role the function assumes (caller-provided: permissions are the caller's design decision)                                                                                     |
| memory_size           | number      | `128`          | Memory allocated to the function, in MB (also scales its CPU share)                                                                                                                                   |
| timeout               | number      | `3`            | Max seconds a single invocation may run before being killed                                                                                                                                           |
| environment_variables | map(string) | `{}`           | Key/value map exposed to the function code as environment variables                                                                                                                                   |
| environment_kms_key_arn | string    | `null`         | Optional customer-managed KMS key ARN for environment variables; null uses the AWS-managed key                                                                                                        |
| publish               | bool        | `false`        | Whether to create an immutable numbered version on every deploy                                                                                                                                       |
| tracing_mode          | string      | `Active`       | X-Ray tracing mode: `Active` (default) or `PassThrough`                                                                                                                                              |
| environment           | string      | -              | Deployment environment this stack belongs to (e.g. lab, development, staging, production). Always stamped as the Environment tag -- no default on purpose: every caller must consciously name its env. |
| tags                  | map(string) | `{}`           | Extra tags applied to every created object                                                                                                                                                           |

## Outputs

| Name           | Description                                                                                       |
|----------------|----------------------------------------------------------------------------------------------------|
| function_name  | Name of the created Lambda function                                                                 |
| function_arn   | ARN of the Lambda function -- useful for IAM policies and event sources                             |
| invoke_arn     | ARN to invoke the function with (for aws_lambda_invocation or API Gateway integration)              |
