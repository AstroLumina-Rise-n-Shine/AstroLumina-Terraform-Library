variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "vcpu" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "RAM in MB"
  type        = number
  default     = 2048
}

variable "disk_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "network_name" {
  description = "libvirt network name"
  type        = string
  default     = "default"
}

variable "disk_pool" {
  description = "Storage pool"
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Tags for the VM"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Deployment environment this VM belongs to (development, staging or production). Written into the guest at /etc/astrolumina-environment and merged into the labels output -- libvirt domains have no native tags, so this is how the env stays visible."
  type        = string
  validation {
    condition     = length(var.environment) > 0
    error_message = "environment must be a non-empty string."
  }
}


variable "base_image_path" {
  description = "Path to the base QCOW2 image"
  type        = string
}

variable "ssh_username" {
  description = "Username for SSH and sudo"
  type        = string
  default     = "ubuntu"
}

variable "ssh_pub_key" {
  description = "SSH public key for authentication"
  type        = string
}

variable "ssh_password" {
  description = "User password (hashed SHA-512)"
  type        = string
  default     = ""
}

variable "running" {
  description = "Whether the VM starts automatically after creation"
  type        = bool
  default     = false
}

variable "mac_address" {
  description = "Optional fixed MAC for the primary NIC. Supply it only if the underlying network uses MAC-based DHCP reservations (the old behaviour); omit it when using direct static IPs via ipv4_address."
  type        = string
  default     = ""

  validation {
    condition     = var.mac_address == "" ? true : can(regex("^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", var.mac_address))
    error_message = "mac_address must be a valid EUI-48 address (xx:xx:xx:xx:xx:xx) or empty."
  }
}

variable "ipv4_address" {
  description = "Static IPv4 address + prefix for the VM's primary interface (e.g. 192.168.200.210/24). When set, cloud-init configures the interface directly, bypassing DHCP reservations entirely — the simpler of the two networking modes."
  type        = string
  default     = ""

  validation {
    condition     = var.ipv4_address == "" ? true : can(cidrhost(var.ipv4_address, 0))
    error_message = "ipv4_address must be a valid CIDR (e.g. 192.168.200.210/24) or empty."
  }
}

variable "ipv4_gateway" {
  description = "IPv4 gateway for the VM. Required when ipv4_address is set (used in cloud-init network config)."
  type        = string
  default     = ""
}

variable "nameservers" {
  description = "Comma-separated DNS nameserver IPs pushed into cloud-init network config"
  type        = string
  default     = "1.1.1.1,8.8.8.8"
}

variable "host_share_path" {
  description = "Host directory shared read-only into the VM via 9p (empty string disables sharing)"
  type        = string
  default     = ""
}

variable "guest_mountpoint" {
  description = "Guest path where the shared directory is mounted"
  type        = string
  default     = "/mnt/k8s"
}

variable "mount_tag" {
  description = "9p mount tag (must match the target dir and the cloud-init mounts entry)"
  type        = string
  default     = "k8s_repo"
}

variable "tailscale_auth_key" {
  description = "Tailscale reusable auth key for automatic tailnet enrollment (empty string disables Tailscale setup)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "project_dns" {
  description = "DNS zone served by dnsmasq on this VM, answered with the node's own Tailscale IP (empty string disables the split-DNS server; requires tailscale_auth_key)"
  type        = string
  default     = ""
}
