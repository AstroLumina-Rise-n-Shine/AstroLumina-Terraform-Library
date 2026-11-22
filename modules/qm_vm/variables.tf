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
  default     = true
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
  description = "Proxmox storage pool for disks and cloud-init ISO (default: local)"
  type        = string
  default     = "local"
}

variable "pm_network_bridge" {
  description = "Linux bridge to attach the VM NIC to (default: vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "pm_ssh_user" {
  description = "SSH user on the Proxmox node (for uploading cloud-init snippet via null_resource)"
  type        = string
  default     = "root"
}

variable "pm_password" {
  description = "Password for the Proxmox SSH user (for null_resource file upload). Optional if using SSH keys."
  type        = string
  default     = ""
  sensitive   = true
}

# -------------------------------------------------------
# Base image / clone source
# -------------------------------------------------------
variable "pm_template" {
  description = "Name of the cloud-init ready VM template to clone (must exist on the Proxmox node)"
  type        = string
  default     = "ubuntu-24.04-cloudinit-template"
}

# -------------------------------------------------------
# Networking – two modes
#   1. dhcp      – no ip_config; Proxmox cloud-init uses ip=dhcp; the guest relies on external DHCP server on the bridge (vmbr0).
#   2. static    – caller supplies ipv4_address / ipv4_gateway; ipconfig0 pins the interface at first boot.
#   mac_address remains optional for both paths – forwarded to Proxmox only when provided.
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
# Tailscale (same contract as libvirt_vm)
# -------------------------------------------------------
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