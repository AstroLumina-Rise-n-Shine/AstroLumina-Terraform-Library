# aws_eks: one EKS cluster per call, workers included.
#
# Each call creates a complete, independent cluster: AWS-managed control
# plane (version pinned via `kubernetes_version`) plus one Managed Node
# Group (EC2 workers EKS maintains for you). For per-env clusters, call the
# module once per env with a different `name` and size. Nothing is shared
# between the calls. Cluster Autoscaler support (IRSA role + discovery tags)
# is optional and off by default.

## Usage

```hcl
module "eks_dev" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_eks?ref=main"

  name             = "astrolumina-development"
  kubernetes_version = "1.29"
  subnet_ids       = ["subnet-aaa", "subnet-bbb"]

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 1

  environment = "development"
}
```

With Cluster Autoscaler IRSA enabled:

```hcl
module "eks_dev" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/aws_eks?ref=main"

  name       = "astrolumina-development"
  subnet_ids = ["subnet-aaa", "subnet-bbb"]

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 5

  enable_cluster_autoscaler = true
  # Defaults: kube-system/cluster-autoscaler. Override only if the chart
  # installs the service account elsewhere.
  cluster_autoscaler_service_account_namespace = "kube-system"
  cluster_autoscaler_service_account_name      = "cluster-autoscaler"

  environment = "development"
}
```

## Cluster Autoscaler (external install, not shipped here)

This module only provisions the **AWS side** of IRSA: the cluster OIDC
provider, an IAM role whose trust policy is scoped to one service account,
a least-privilege policy (describe autoscaling/EC2/EKS inventory; change
capacity only on ASGs tagged for *this* cluster), and the two discovery
tags on the node group. No Kubernetes manifest or Helm chart for Cluster
Autoscaler lives in this repository -- install it from the upstream chart:

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=astrolumina-development \
  --set awsRegion=eu-west-1 \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set "rbac.serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$(terraform output -raw cluster_autoscaler_role_arn)"
```

- `autoDiscovery.clusterName` + the module's
  `k8s.io/cluster-autoscaler/enabled=true` and
  `k8s.io/cluster-autoscaler/<cluster-name>=owned` tags are how the chart
  finds the ASGs it owns; no `nodeGroupAutoDiscovery` list is needed.
- `awsRegion` must be the cluster's region (the chart does not infer it).
- The service account name/namespace in the Helm values **must match** the
  module variables, otherwise the IAM trust policy (`:sub` condition)
  refuses the web-identity token.
- The role ARN goes in the `eks.amazonaws.com/role-arn` service account
  annotation, produced by the chart from
  `rbac.serviceAccount.annotations`.

## Notes

- `environment` (required) is always stamped as the `Environment` tag on
  every object, alongside the standard `Project`/`ManagedBy` tags -- this
  is what tells per-env clusters apart. Extra `tags` merge underneath.
- `subnet_ids` is deliberately explicit: the module performs no
  data-source lookups, so the caller stays in control (and Floci, whose
  default VPC varies, never surprises you).
- Workers are a Managed Node Group, not hand-made EC2 instances: EKS owns
  the AMI, the bootstrap, and the rolling updates.
- With `enable_cluster_autoscaler = true`, Terraform sets the node group's
  initial `desired_size` to `min_size` (not `desired_size`) so the two
  controllers do not disagree at creation. Cluster Autoscaler owns the
  running node count after that. Disabled, `desired_size` behaves exactly
  as before.
- The autoscaler policy cannot touch another cluster: write actions carry
  a condition on the `k8s.io/cluster-autoscaler/<cluster-name>` resource
  tag, and the create/delete of nodes is not granted.
- Enabling the autoscaler registers the cluster's OIDC issuer as an IAM
  identity provider. Exactly one such provider can exist per cluster: if
  it was created outside this module, import it
  (`terraform import module.<name>.aws_iam_openid_connect_provider.this[0] <arn>`)
  instead of letting the apply fail on a duplicate.
- Reading the issuer thumbprint uses `data "tls_certificate"`, so *when
  enabled* plan/apply needs outbound HTTPS to the OIDC issuer. Disabled
  (the default) the data source is counted out and no extra call is made.
- Tested against the Floci emulator (`eks`, `ec2`, `iam`, `autoscaling`
  services); on real AWS the same code works unchanged, only the provider
  endpoints and credentials differ (see the Floci setup guides in AstroLumina-AWS).

## Inputs

| Name                                             | Type         | Default              | Description |
| ------------------------------------------------ | ------------ | -------------------- | ----------- |
| `name`                                           | string       | n/a                  | Cluster name (also prefixes IAM roles and node group) |
| `kubernetes_version`                             | string       | `"1.29"`             | Kubernetes control-plane version managed by EKS |
| `subnet_ids`                                     | list(string) | n/a                  | Explicit subnet IDs for cluster and nodes |
| `cluster_encryption_key_arn`                     | string       | n/a                  | KMS key ARN for EKS secrets envelope encryption |
| `instance_types`                                 | list(string) | `["t3.small"]`       | EC2 instance types for the managed worker nodes |
| `desired_size`                                   | number       | `1`                  | Desired worker node count (ignored in favour of `min_size` when the autoscaler is enabled) |
| `min_size`                                       | number       | `1`                  | Minimum worker node count |
| `max_size`                                       | number       | `1`                  | Maximum worker node count |
| `enable_cluster_autoscaler`                      | bool         | `false`              | Create the OIDC provider, IRSA role/policy and node-group discovery tags |
| `cluster_autoscaler_service_account_namespace`   | string       | `"kube-system"`      | Namespace trusted by the autoscaler role |
| `cluster_autoscaler_service_account_name`        | string       | `"cluster-autoscaler"` | Service account name trusted by the autoscaler role |
| `tags`                                           | map(string)  | `{}`                 | Tags applied to every created object |
| `environment`                                    | string       | n/a                  | Deployment environment; always stamped as the `Environment` tag |

## Outputs

| Name                          | Description |
| ----------------------------- | ----------- |
| `cluster_name`                | Name of the EKS cluster |
| `cluster_endpoint`            | API server endpoint of the EKS control plane |
| `cluster_arn`                 | ARN of the EKS cluster |
| `node_group_name`             | Name of the managed worker node group |
| `cluster_autoscaler_role_arn` | IRSA role ARN to annotate on the autoscaler service account (null when disabled) |
