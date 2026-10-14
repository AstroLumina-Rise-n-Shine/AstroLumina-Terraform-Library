# EKS clusters with Terraform (learned on Floci)

## Can you have one cluster per env?

Yes. An EKS cluster is just an API object with a name: call
`modules/eks_cluster` once per env with a different `name` and size, and
you get three fully independent clusters (see
`examples/eks-clusters`, verified end-to-end against Floci: three clusters
`astrolumina-development/staging/production`, each with its own node
group, then destroyed cleanly). Nothing is shared between them -- separate
API endpoints, separate node groups, separate IAM roles.

## Who manages what

- **Control plane (API server, etcd, scheduler): fully AWS-managed.**
  You never create, size, patch, or SSH into masters. You only pick the
  Kubernetes `version` and the `subnet_ids`. AWS runs the masters and
  charges per cluster-hour (about $0.10/hour per cluster on real AWS --
  three always-on learning clusters cost real money, prefer creating them
  for a session and destroying afterwards).
- **Workers: Managed Node Groups, not hand-made EC2.** You do NOT create
  EC2 instances and join them yourself. `aws_eks_node_group` declares
  `instance_types` plus desired/min/max size, and EKS provisions the EC2
  instances, installs the right AMI, bootstraps the kubelet, registers the
  nodes, and performs rolling updates. The three IAM attachments on the
  node role (worker base, ECR read, CNI networking) are exactly what the
  bootstrap needs -- nothing more.

So the mental model is: *you declare cluster + size, AWS delivers nodes.*

## Minimal sizes for learning

`t3.small` with desired 1 (dev/staging) or 2 (production) is enough to see
nodes register, schedule a pod, and practice `kubectl`. Floci runs no real
kubelet, so there the nodes exist as API objects only -- the Terraform
shape (roles, cluster, node group, scaling) is identical to real AWS,
which is what you are learning here.

## Real cluster vs learning clusters

The production workload (ArgoCD and everything built so far) stays on the
RKE2 VMs in KVM -- that is the real cluster. EKS here is the learning
track: same Terraform language, same Kubernetes concepts, zero risk to the
real platform. If EKS ever becomes the real target, the promotion path is
the module itself: same `eks_cluster` calls, pointed at real AWS
credentials instead of the emulator endpoints.
