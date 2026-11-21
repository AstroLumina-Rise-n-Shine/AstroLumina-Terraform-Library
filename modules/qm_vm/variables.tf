variable "vm_name" {
  description = "Proxmox VM name (also used as Cloud-Init hostname)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_-]*$", var.vm_name))
    error_message = "vm_name must start with a letter and contain only letters, digits, hyphens and underscores."
  }
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
  description = "Main OS disk size in GB"
  type        = number
  default     = 20
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
  description = "User password (plain text - hashed by cloud-init)"
  type        = string
  default     = ""
}

variable "running" {
  description = "Whether the VM starts automatically after creation"
  type        = bool
  default     = false
}

variable "environment" {
  description = "Deployment environment label written into /etc/astrolumina-environment"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "environment must be a non-empty string."
  }
}

variable "tags" {
  description = "Tags for the VM (written into /etc/astrolumina-environment)"
  type        = map(string)
  default     = {}
}

# -------------------------------------------------------
# Proxmox infrastructure pointers
# -------------------------------------------------------
variable "pm_api_url" {
  description = "Proxmox VE API endpoint (e.g. https://192.168.100.22:8006)"
  type        = string
}

variable "pm_node" {
  description = "Proxmox node name where the VM will be created"
  type        = string
}

variable "pm_storage" {
  description = "Proxmox storage pool for disks (default: local)"
  type        = string
  default     = "local"
}

variable "pm_network_bridge" {
  description = "Linux bridge to attach the VM NIC to (default: vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "pm_ssh_user" {
  description = "SSH user used to reach the Proxmox API node (for cloud-init iso upload when not using a pre-existing template)"
  type        = string
  default     = "root"
}

variable "pm_ssh_host" {
  description = "SSH target to upload the cloud-init ISO to; defaults to pm_api_url host when omitted"
  type        = string
  default     = ""
}

# -------------------------------------------------------
# Base image / clone source
# -------------------------------------------------------
variable "base_image_path" {
  description = "QCOW2 path inside Proxmox storage (e.g. local:base/ubuntu-24.04.qcow2). When empty, a new disk is carved from the cloud-image URL below."
  type        = string
  default     = ""
}

variable "cloud_image_url" {
  description = "URL to download a cloud-init-ready image when base_image_path is empty (used during preflight init, not during apply)"
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

# -------------------------------------------------------
# Networking – two modes
#   1. dhcp      – no ip_config; the proxmox DHCP server hands out an address (stable if the host's dhclient has reservations, or purely dynamic otherwise).
#   2. static    – caller supplies ipv4_address / ipv4_gateway; the guest receives a fixed LAN address directly via cloud-init.
#   mac_address remains optional for both paths – it is forwarded to Proxmox only when provided.
# -------------------------------------------------------
variable "mac_address" {
  description = "Optional fixed MAC for the primary NIC. When provided, Proxmox will honour it; leave blank for auto-generated"
  type        = string
  default     = ""

  validation {
    condition     = var.mac_address == "" ? true : can(regex("^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$", var.mac_address))
    error_message = "mac_address must be a valid EUI-48 address (xx:xx:xx:xx:xx:xx) or empty."
  }
}

variable "ipv4_address" {
  description = "Static IPv4 address + prefix for the primary NIC (e.g. 192.168.100.10/24). Required when you want a fixed LAN IP; ignored when empty (DHCP mode)."
  type        = string
  default     = ""

  validation {
    condition     = var.ipv4_address == "" ? true : can(cidrhost(var.ipv4_address, 0))
    error_message = "ipv4_address must be a valid CIDR (e.g. 192.168.100.10/24) or empty."
  }
}

variable "ipv4_gateway" {
  description = "IPv4 gateway for the VM. Required when ipv4_address is set; ignored in DHCP mode."
  type        = string
  default     = ""
}

variable "nameservers" {
  description = "Comma-separated list of DNS nameserver IPs pushed into cloud-init network config"
  type        = string
  default     = "1.1.1.1,8.8.8.8"
}

# -------------------------------------------------------
# Optional 9p-style read-only share of a host directory
# (mounted inside the guest at guest_mountpoint under mount_tag)
# -------------------------------------------------------
variable "host_share_path" {
  description = "Host directory shared read-only into the VM (via an NFS export or rsync step run by tf.sh; Proxmox doesn't have virtio-9p natively)."
  type        = string
  default     = ""
}

variable "guest_mountpoint" {
  description = "Guest path where the share is mounted"
  type        = string
  default     = "/mnt/k8s"
}

variable "mount_tag" {
  description = "Logical tag identifying the share (written into /etc/fstab on the guest)"
  type        = string
  default     = "k8s_repo"
}

# -------------------------------------------------------
# Tailscale (same contract as libvirt_vm)
# -------------------------------------------------------
variable "tailscale_auth_key" {
  description = "Tailscale reusable auth key for automatic tailnet enrollment (empty string disables Tailscale setup)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tailnet_dns_zone" {
  description = "DNS zone served by dnsmasq on this VM, answered with the node's own Tailscale IP (empty string disables the split-DNS server; requires tailscale_auth_key)"
  type        = string
  default     = ""
}
