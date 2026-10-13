# AstroLumina-Terraform-Library

Reusable Terraform modules plus the learning path around them: installing
Terraform, emulating AWS locally with Floci, and wiring the two together.
The live infrastructure composition (development / staging / production)
lives in [AstroLumina-Terraform](https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform),
which consumes these modules via `source = "git::...//modules/<name>"`.

## Layout

```
modules/
  kvm_vm/          # Single KVM virtual machine (libvirt + cloud-init)
  eks_cluster/     # EKS cluster + managed node group (control plane managed by AWS)
docs/
  01-terraform-install.md   # Terraform via the official HashiCorp APT repo
  02-floci-aws-cli.md       # Floci + AWS CLI install, pointing the CLI at Floci
  03-terraform-floci.md     # AWS provider wiring for the emulator + EKS roadmap
  04-eks-clusters.md       # Per-env EKS clusters, managed control plane vs node groups
examples/
  floci-s3-bucket/  # Minimal S3 bucket on Floci (verified end-to-end)
  eks-clusters/     # One minimal EKS cluster per env on Floci (verified end-to-end)
```

## Module contract

Every module ships `main.tf` + `variables.tf` (+ `outputs.tf` when it
exports anything) + a `README.md` with inputs/outputs tables. New AWS
modules (`aws_vpc`, `eks`, ...) follow the same shape and are developed
against Floci first.

## Referencing a module

```hcl
module "vm" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/kvm_vm?ref=main"
  # ...inputs...
}
```

`?ref=main` tracks the default branch (fine for a learning repo; pin a tag
or SHA when stability matters more than freshness).
