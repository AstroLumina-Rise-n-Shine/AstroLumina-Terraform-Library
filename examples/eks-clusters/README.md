# eks-clusters example

Three minimal EKS clusters (development / staging / production) on the
Floci emulator, one module call each. Dev and staging run a single
`t3.small` worker, production runs two.

```bash
floci start
terraform init
terraform apply   # then verify with: aws --endpoint-url=http://localhost:4566 eks list-clusters
terraform destroy # Floci has no real kubelet; destroy when done learning
```

Proven end-to-end: apply created all three clusters plus their node
groups (27 resources), `list-clusters` showed all three,
`list-nodegroups` showed each `-workers` group, destroy removed
everything (cluster list empty afterwards).
