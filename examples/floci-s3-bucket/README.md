# Sanity example: one S3 bucket in the Floci emulator.

Uses the provider wiring from `docs/03-terraform-floci.md`. Full loop:

```bash
floci start
eval "$(floci env)"
terraform init
terraform apply -auto-approve
aws s3api list-buckets --query 'Buckets[].Name'
terraform destroy -auto-approve
```
