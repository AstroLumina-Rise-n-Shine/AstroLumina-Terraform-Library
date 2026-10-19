# Standard tags for every object this module creates. Caller tags win on
# key conflicts, except Environment, which always comes from var.environment
# so instances from different envs can never look identical.
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

# A single EC2 instance in a caller-provided subnet. The module deliberately
# does no lookups: AMI, subnet and security groups are all passed in, so the
# caller stays in control and the module works unchanged against an emulator
# whose default VPC keeps shifting. Floci maps any AMI ID to its local
# runtime image; real AWS needs a real (region-correct) AMI.
resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address

  # Cloud-init style script executed on first boot (rename the host, install
  # a package, print instance metadata for demos...). Keep it short here and
  # put real sprawl in bash-side provisioning.
  user_data = var.user_data

  # IMDSv2 only: metadata requests must present a session token, which
  # kills the classic SSRF-to-credentials attack path (Trivy AWS-0028).
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Encrypt the boot volume (Trivy AWS-0131); gp3 is the modern default
  # volume type on real AWS.
  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

  tags = merge(local.common_tags, { Name = var.name })
}
