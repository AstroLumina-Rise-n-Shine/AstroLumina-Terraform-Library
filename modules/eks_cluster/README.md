# eks_cluster: one EKS cluster per call, workers included.
#
# Each call creates a complete, independent cluster: AWS-managed control
# plane (version pinned via `kubernetes_version`) plus one Managed Node
# Group (EC2 workers EKS maintains for you). For per-env clusters, call the
# module once per env with a different `name` and size (see
# examples/eks-clusters). Nothing is shared between the calls.

## Usage

```hcl
module "eks_dev" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/eks_cluster?ref=main"

  name             = "astrolumina-dev"
  kubernetes_version = "1.29"
  subnet_ids       = ["subnet-aaa", "subnet-bbb"]

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 1

  environment = "development"
}
```

## Notes

- `environment` (required) is always stamped as the `Environment` tag on
  every object, alongside the standard `Project`/`ManagedBy` tags -- this
  is what tells per-env clusters apart. Extra `tags` merge underneath.

## Notes

- `subnet_ids` is deliberately explicit: the module performs no
  data-source lookups, so the caller stays in control (and Floci, whose
  default VPC varies, never surprises you).
- Workers are a Managed Node Group, not hand-made EC2 instances: EKS owns
  the AMI, the bootstrap, and the rolling updates.
- Tested against the Floci emulator (`eks`, `ec2`, `iam`, `autoscaling`
  services); on real AWS the same code works unchanged, only the provider
  endpoints and credentials differ (see docs/04-eks-clusters.md).
