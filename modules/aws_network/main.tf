# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so networks from different envs can never look identical.
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
}

# The VPC itself: a private IP range the rest of the environment lives in.
# DNS support + hostnames are on because many AWS features (RDS endpoints,
# S3 private endpoints) resolve names that only work with both enabled.
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${var.name}-vpc" })
}

# Internet gateway = the VPC's front door to the internet. Without it the
# public subnets are just IP ranges with a door painted on the wall.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, { Name = "${var.name}-igw" })
}

# Public subnets: resources here get a public IP at launch, and the public
# route table below sends their traffic through the IGW. The availability
# zone is taken positionally from var.availability_zones; when the list is
# empty, each subnet simply lands in an emulator-chosen AZ. On real AWS you
# should pass at least two AZs (or more) so subnets spread out properly.
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > count.index ? var.availability_zones[count.index] : null

  # Secure default (false): public subnets are internet-routable through
  # the route table below, but instances only auto-get a public IP when
  # the caller explicitly asks (var.map_public_ip_on_launch = true).
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.common_tags, { Name = "${var.name}-public-${count.index + 1}" })
}

# Private subnets: resources here never get a public IP and reach the
# internet (when NAT is enabled) only outbound, via the NAT gateway.
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = length(var.availability_zones) > count.index ? var.availability_zones[count.index] : null

  map_public_ip_on_launch = false

  tags = merge(local.common_tags, { Name = "${var.name}-private-${count.index + 1}" })
}

# One public route table, shared by all public subnets: default route out
# through the internet gateway. This is the classic public-tier shortcut.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.common_tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# One route table per PRIVATE subnet (plural on purpose: when NAT exists
# each table points at the same gateway, but keeping them separate leaves
# room for egress filtering later). The default route appears only when
# NAT is enabled -- without it, private subnets are purely internal, which
# is exactly what the cost-conscious default (enable_nat_gateway = false)
# asks for: NAT gateways charge per hour on real AWS.
resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id = aws_vpc.this.id

  # Optional outbound default route through the single shared NAT gateway.
  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.this[0].id
    }
  }

  tags = merge(local.common_tags, { Name = "${var.name}-private-rt-${count.index + 1}" })
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Optional single-NAT architecture: one Elastic IP + one NAT gateway,
# anchored in the first public subnet, serving every private subnet.
# Cheapest workable pattern; production usually adds one NAT per AZ.
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = merge(local.common_tags, { Name = "${var.name}-nat" })
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, { Name = "${var.name}-nat" })

  # Wait for the IGW before creating the NAT gateway: provisioning order
  # here is load-bearing (the NAT gateway needs its public subnet online).
  depends_on = [aws_internet_gateway.this]
}
