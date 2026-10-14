# 03 -- Wiring Terraform to Floci (and later to real AWS/EKS)

The AWS provider assumes real AWS: real STS for credential validation,
real EC2 metadata, a real account ID. Against an emulator every one of
those calls must be disabled or redirected, otherwise `init`/`apply` fail
before touching any resource. The block below is the complete wiring;
`examples/floci-s3-bucket` applies it to a real (emulated) bucket and is
verified end-to-end in CI fashion locally.

## The provider block

```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    sts = "http://localhost:4566"
    iam = "http://localhost:4566"
    # Add one line per AWS service the configuration touches
    # (ec2, eks, elb, ...), all with the same URL.
  }
}
```

Why each line exists:

- `endpoints` -- redirects API calls from `*.amazonaws.com` to the
  emulator. One entry per service used; anything missing an entry goes to
  real AWS (and fails without network credentials).
- `access_key / secret_key = "test"` -- Floci accepts any non-empty values.
  They only satisfy the provider's "credentials must exist" check.
- `skip_credentials_validation` -- stops the provider from calling real STS
  `GetCallerIdentity` to validate the dummy keys.
- `skip_metadata_api_check` -- stops the EC2 metadata lookup (there is no
  EC2 metadata endpoint on a laptop).
- `skip_requesting_account_id` -- stops the real STS account-ID lookup.
- `s3_use_path_style` -- the emulator serves `http://host:4566/bucket/key`,
  not virtual-hosted `http://bucket.host/...` style URLs (which would need
  per-bucket DNS entries to resolve locally).

Credentials can also come from `eval "$(floci env)"` (same `test` values
plus `AWS_ENDPOINT_URL`); explicit keys in the block keep Terraform runs
independent of shell state, which is why the example hardcodes them.

## Full loop (verified)

```bash
floci start
eval "$(floci env)"

cd examples/floci-s3-bucket
terraform init
terraform apply -auto-approve
# bucket_name = "astrolumina-terraform-test"

aws s3api list-buckets --query 'Buckets[].Name'
# ["astrolumina-terraform-test"]

terraform destroy -auto-approve
floci stop
```

## Road to EKS (and other AWS modules)

New AWS modules will live next to the KVM ones (`modules/aws_vpc`,
`modules/eks`, ...), following the same contract: `main.tf` +
`variables.tf` (+ `outputs.tf` when the module exports anything) + a short
`README.md` with inputs/outputs tables. Develop each against Floci first --
EKS-flavored services run as real Docker workloads under Floci, so cluster
shape can be iterated locally -- and only then point the same module at a
real account by swapping the provider endpoints for a profile/role.
