terraform {
  # hashicorp/tls is only used to read the OIDC issuer certificate thumbprint
  # for the optional Cluster Autoscaler IRSA provider. Callers that leave
  # enable_cluster_autoscaler = false pay nothing: the data source is counted
  # out and never queried.
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
  }
}

# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so clusters from different envs can never look identical.
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

  # Cluster Autoscaler discovery tags. CA finds the ASGs it may manage by
  # looking for these two tags, so they must land on the node group (EKS
  # propagates node group tags down to the underlying ASG). Empty when the
  # autoscaler is disabled, so existing callers see no tag changes.
  autoscaler_tags = var.enable_cluster_autoscaler ? {
    "k8s.io/cluster-autoscaler/enabled"     = "true"
    "k8s.io/cluster-autoscaler/${var.name}" = "owned"
  } : {}

  # IRSA trust policies key their conditions on the issuer host (the issuer
  # URL without the scheme) plus the service account namespace/name.
  oidc_issuer      = var.enable_cluster_autoscaler ? aws_eks_cluster.this.identity[0].oidc[0].issuer : null
  oidc_issuer_host = var.enable_cluster_autoscaler ? replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") : null

  # With the autoscaler owning the node count, Terraform pins the initial
  # desired size to the floor (min_size) instead of fighting CA with a
  # second opinion. Disabled behaviour is unchanged.
  node_group_desired_size = var.enable_cluster_autoscaler ? var.min_size : var.desired_size
}

# IAM role assumed by the EKS control plane (managed by AWS, you never see
# the masters). Needs exactly one managed policy: AmazonEKSClusterPolicy.
resource "aws_iam_role" "cluster" {
  name = "${var.name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM role assumed by the worker nodes (EC2 instances). Needs three managed
# policies: worker-node base, ECR image pulls, and VPC CNI networking.
resource "aws_iam_role" "node" {
  name = "${var.name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# The cluster itself: AWS provisions and operates the Kubernetes control
# plane (API server, etcd, scheduler). You only pick the version and the
# subnets it lives in. No masters to size, patch, or pay per-node for.
resource "aws_eks_cluster" "this" {
  name     = var.name
  version  = var.kubernetes_version
  role_arn = aws_iam_role.cluster.arn

  # Ship every control-plane log type to CloudWatch Logs. The API default
  # logs nothing, which Trivy flags five times over (AWS-0038). On real AWS
  # this incurs CloudWatch ingestion charges; on Floci it is free.
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = var.subnet_ids

    # Private-only API endpoint: the control plane is NOT reachable from the
    # public internet. Worker nodes reach it inside the VPC. (Trivy AWS-0040
    # fires on the default public endpoint, AWS-0041 on the default
    # 0.0.0.0/0 CIDRs -- both gone with public access disabled.)
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  # Envelope encryption for Kubernetes secrets with a caller-provided KMS
  # key. Without this block etcd stores secrets unencrypted at rest.
  # (Trivy AWS-0039.) A shared key per deployment is fine for learning;
  # production would use one key per cluster.
  encryption_config {
    resources = ["secrets"]

    provider {
      key_arn = var.cluster_encryption_key_arn
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Optional Cluster Autoscaler IRSA (enable_cluster_autoscaler)
# ---------------------------------------------------------------------------
# IRSA ("IAM Roles for Service Accounts") is how a pod gets AWS permissions
# without node-wide credentials: the cluster's OIDC issuer becomes an IAM
# identity provider, and the pod's service account is allowed to assume a
# role through a web-identity token. The Helm chart that runs Cluster
# Autoscaler lives outside this repo; this module only provisions the AWS
# side (provider, role, least-privilege policy).

# The OIDC issuer certificate, read over TLS to compute the thumbprint the
# IAM provider requires. Counted out when the autoscaler is disabled so a
# default module call makes no extra API/network call.
data "tls_certificate" "this" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  url = local.oidc_issuer
}

# Register the cluster's OIDC issuer as an identity provider. This is the
# anchor every IRSA role in the cluster trusts; one provider per cluster.
resource "aws_iam_openid_connect_provider" "this" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  url             = local.oidc_issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.this[0].certificates[0].sha1_fingerprint]

  tags = local.common_tags
}

# The role Cluster Autoscaler's service account assumes. The trust policy is
# scoped twice: to this cluster's OIDC provider, and to exactly one
# namespace/name pair -- no other service account in the cluster can use it.
resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name = "${var.name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.this[0].arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_issuer_host}:sub" = "system:serviceaccount:${var.cluster_autoscaler_service_account_namespace}:${var.cluster_autoscaler_service_account_name}"
          "${local.oidc_issuer_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

# Least privilege for Cluster Autoscaler: it may READ the autoscaling/EC2/EKS
# inventory (describe-only), but may only CHANGE capacity on ASGs carrying
# this cluster's `k8s.io/cluster-autoscaler/<cluster-name> = owned` tag. The
# tag condition is what stops a compromised autoscaler from scaling (or
# terminating) another cluster's nodes in the same account.
resource "aws_iam_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name        = "${var.name}-cluster-autoscaler"
  description = "Least-privilege Cluster Autoscaler policy for ${var.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DescribeAutoscalingInventory"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeLaunchTemplates",
        ]
        Resource = "*"
      },
      {
        Sid    = "DescribeManagedNodeGroups"
        Effect = "Allow"
        Action = [
          "eks:DescribeNodegroup",
        ]
        Resource = "*"
      },
      {
        Sid    = "ScaleTaggedNodeGroups"
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.name}" = "owned"
          }
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}

# Workers as a Managed Node Group: EKS creates and maintains the EC2
# instances for you (AMI, bootstrap, join, rolling updates). You do NOT
# create EC2 instances by hand -- you declare instance types and desired
# size, and the group keeps that many nodes registered in the cluster.
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name}-workers"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  instance_types = var.instance_types

  scaling_config {
    desired_size = local.node_group_desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  tags = merge(local.common_tags, local.autoscaler_tags)
}
