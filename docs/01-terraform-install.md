# 01 -- Installing Terraform on Linux (Ubuntu 24.04)

Install from the official HashiCorp APT repository (never from the distro
pool -- it ships ancient versions). Verified with Terraform v1.15.0.

```bash
# 1. Prerequisites (curl + gnupg for the repo key)
sudo apt-get update
sudo apt-get install -y curl gnupg

# 2. HashiCorp GPG key -> keyring
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp.gpg
sudo chmod 0644 /etc/apt/keyrings/hashicorp.gpg

# 3. Repository entry (uses the current Ubuntu codename automatically)
echo "deb [signed-by=/etc/apt/keyrings/hashicorp.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

# 4. Install
sudo apt-get update
sudo apt-get install -y terraform
```

Verify:

```bash
terraform version
# Terraform v1.15.0 (or newer) on linux_amd64
```

Upgrades later are `sudo apt-get update && sudo apt-get install -y terraform`.
Pinning is intentionally not covered here: this is a learning repo and the
modules only require `>= 1.0`.

Next: [02 -- Floci + AWS CLI](02-floci-aws-cli.md).
