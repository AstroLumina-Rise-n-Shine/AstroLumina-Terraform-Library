# One EKS cluster per environment, minimal sizes for learning.
#
# Run `floci start`, export the connection variables, then init/apply.
# Everything lives inside the emulator (see `floci snapshot` to persist
# emulator state across restarts). Floci runs no real kubelet, so the nodes
# register as API objects only -- perfect for learning the Terraform shape,
# not for running pods.

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Every endpoint points at the local emulator instead of real AWS.
# Credentials are dummy values: Floci accepts anything, but the AWS
# provider still requires the validation skips below, otherwise init
# fails trying to reach the real STS/metadata endpoints.
provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2         = "http://localhost:4566"
    eks         = "http://localhost:4566"
    elb         = "http://localhost:4566"
    iam         = "http://localhost:4566"
    sts         = "http://localhost:4566"
    autoscaling = "http://localhost:4566"
  }
}

# One small VPC for all three clusters. Real AWS users would reuse existing
# subnets; creating our own keeps the example self-contained on Floci too.
resource "aws_vpc" "eks" {
  cidr_block = "10.1.0.0/16"

  tags = { Name = "astrolumina-eks" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.eks.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "astrolumina-eks-a" }
}

resource "aws_subnet" "b" {
  vpc_id            = aws_vpc.eks.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "astrolumina-eks-b" }
}

locals {
  subnets = [aws_subnet.a.id, aws_subnet.b.id]
}

# One shared KMS key for EKS secrets encryption across the three learning
# clusters (the eks_cluster module requires a key ARN -- see its
# cluster_encryption_key_arn variable). Production would use one key
# per cluster for blast-radius isolation.
resource "aws_kms_key" "eks_secrets" {
  description = "Shared envelope-encryption key for the learning EKS clusters"
}

module "eks_development" {
  source = "../../modules/eks_cluster"

  name                       = "astrolumina-development"
  subnet_ids                 = local.subnets
  cluster_encryption_key_arn = aws_kms_key.eks_secrets.arn

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 1

  tags = { env = "development" }
}

module "eks_staging" {
  source = "../../modules/eks_cluster"

  name                       = "astrolumina-staging"
  subnet_ids                 = local.subnets
  cluster_encryption_key_arn = aws_kms_key.eks_secrets.arn

  instance_types = ["t3.small"]
  desired_size   = 1
  min_size       = 1
  max_size       = 1

  tags = { env = "staging" }
}

module "eks_production" {
  source = "../../modules/eks_cluster"

  name                       = "astrolumina-production"
  subnet_ids                 = local.subnets
  cluster_encryption_key_arn = aws_kms_key.eks_secrets.arn

  instance_types = ["t3.small"]
  desired_size   = 2
  min_size       = 2
  max_size       = 2

  tags = { env = "production" }
}

output "cluster_endpoints" {
  description = "API endpoints of the three per-env clusters"
  value = {
    development = module.eks_development.cluster_endpoint
    staging     = module.eks_staging.cluster_endpoint
    production  = module.eks_production.cluster_endpoint
  }
}
