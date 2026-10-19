# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so functions from different envs can never look identical.
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

# One Lambda function packaged from a local zip file. The execution role is
# caller-provided on purpose: permissions are the caller's design decision,
# and the module has no business inventing IAM policies. Change
# source_code_hash every time the zip changes, or Terraform will happily
# keep deploying the old code -- `filebase64sha256(file(var.filename))` is
# the usual incantation on the calling side.
resource "aws_lambda_function" "this" {
  filename         = var.filename
  source_code_hash = var.source_code_hash

  function_name = var.name
  role          = var.role_arn
  handler       = var.handler
  runtime       = var.runtime

  memory_size = var.memory_size
  timeout     = var.timeout

  # Version the function on every deploy (publish = true) only when you
  # want immutable, invocable "versions" of it; plain learning deploys
  # don't need the extra $LATEST-version dance.
  publish = var.publish

  # Environment variables: the config surface between the function and the
  # rest of the stack (table names, endpoints...). Numbers come out as
  # strings, so code should treat them like strings.
  environment {
    variables = var.environment_variables
  }

  tags = merge(local.common_tags, { Name = var.name })
}
