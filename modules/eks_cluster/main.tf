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

  tags = var.tags
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

  tags = var.tags
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

  tags = var.tags
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
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }

  tags = var.tags
}
