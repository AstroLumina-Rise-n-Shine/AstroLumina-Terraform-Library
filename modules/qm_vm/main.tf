# Proxmox VM Module
# terraform-provider-proxmox (pve) – see https://registry.terraform.io/providers/Terraform-Proxmox/proxmox/latest
#
# Design notes:
# * The module talks to the Proxmox API. It does NOT require virsh / libvirt.
# * Two networking modes are supported:
#   - DHCP (default): omit ipv4_address + ipv4_gateway; Proxmox's internal DHCP
#     hands out an address. On a bare bridge (vmbr0) there is no DHCP server,
#     so the host OS dhclient (or a external relay) must serve leases. In
 #    practice the lab relies on the guest picking .10/.11/.12 via a
 #    reservation on the upstream router/firewall; no MAC pinning is required.
#   - Static: provide ipv4_address + ipv4_gateway; cloud-init configures the
#     interface directly at first boot, bypassing any lease table.
# * mac_address is OPTIONAL. When supplied it is passed through; when omitted
#   Proxmox generates one. This drops the previous MAC <-> DHCP-reservation
#   coupling that forced every environment to know every guest MAC ahead of
#   time.
# * Cloud-init runs natively on Proxmox; no separate ISO trick is needed.

terraform {
  required_providers {
    proxmox = {
      source  = "Terraform-Proxmox/proxmox"
      version = "~> 2.5"
    }
  }
}

locals {
  common_labels = merge(var.tags, {
    Environment = var.environment
  })

  ssh_pub_key_line = trim(var.ssh_pub_key, " \n\r\t")

  # Build the Proxmox cloud-init network config block.
  # In DHCP mode the block is empty; in STATIC mode it pins the interface.
  cloud_init_network_config = var.ipv4_address != "" ? <<-EOF
    version: 1
    config:
      - type: physical
        name: eth0
        subnets:
          - type: static
            address: ${var.ipv4_address}
            control: manual
            gateway: ${var.ipv4_gateway}
            dns-nameservers: [${join(", ", split(",", var.nameservers))}]
  EOF
    : ""
}

# ============================================================
# Cloud-Init user-data (sent via proxmox_cloud_init_disk)
# ============================================================
resource "proxmox_cloud_init_disk" "this" {
  name      = "${var.vm_name}-ci"
  node_name = var.pm_node
  storage   = var.pm_storage

  user_data = <<-EOF
#cloud-config
users:
  - name: ${var.ssh_username}
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, sudo
    home: /home/${var.ssh_username}
    shell: /bin/bash
    ssh_authorized_keys:
      - ${local.ssh_pub_key_line}
%{if var.ssh_password != ""}
    passwd: "${var.ssh_password}"
%{endif}

ssh_pwauth: ${var.ssh_password != "" ? "true" : "false"}
%{if var.tailscale_auth_key != "" && var.tailnet_dns_zone != ""}
packages:
  - dnsmasq
%{endif}

write_files:
  - path: /etc/astrolumina-environment
    permissions: '0644'
    content: |
%{for k, v in local.common_labels}      ${k}=${v}
%{endfor}
%{if var.tailscale_auth_key != "" && var.tailnet_dns_zone != ""}
  - path: /etc/dnsmasq.d/tailnet-base.conf
    permissions: '0644'
    content: |
      interface=tailscale0
      bind-interfaces
  - path: /usr/local/sbin/tailnet-dns-apply.sh
    permissions: '0755'
    content: |
      #!/bin/bash
      ZONE="$1"
      TS_IP=""
      for _ in $(seq 1 60); do
        TS_IP=$(tailscale ip -4 2>/dev/null | head -n 1)
        case "$TS_IP" in 100.*) break ;; *) TS_IP="" ;; esac
        sleep 5
      done
      if [ -z "$TS_IP" ]; then
        echo "tailnet-dns-apply: no Tailscale IPv4 yet, giving up" >&2
        exit 1
      fi
      echo "address=/$${ZONE}/$${TS_IP}" > /etc/dnsmasq.d/tailnet-zone.conf
      systemctl enable --now dnsmasq
      systemctl restart dnsmasq
%{endif}
%{if var.tailscale_auth_key != ""}
  - path: /etc/systemd/system/tailnet-pod-routing.service
    permissions: '0644'
    content: |
      [Unit]
      Description=Steer tailnet-bound traffic to Tailscale table 52 (fix Calico fwmark vs Tailscale policy routing)
      After=network-online.target tailscaled.service
      Wants=network-online.target

      [Service]
      Type=oneshot
      RemainAfterExit=yes
      ExecStart=/bin/sh -c 'ip rule show | grep -q "to 100.64.0.0/10 lookup 52" || ip rule add to 100.64.0.0/10 lookup 52 pref 5200; ip -6 rule show | grep -q "fd7a:115c:a1e0::/48 lookup 52" || ip -6 rule add to fd7a:115c:a1e0::/48 lookup 52 pref 5200'

      [Install]
      WantedBy=multi-user.target
%{endif}

runcmd:
  - echo '${var.ssh_username}:${var.ssh_password}' | chpasswd
  - systemctl enable ssh
  - systemctl start ssh
  - apt update && apt upgrade -y
%{if var.tailscale_auth_key != ""}
  - curl -fsSL https://tailscale.com/install.sh | sh
  - tailscale up --authkey='${var.tailscale_auth_key}' --hostname=${var.vm_name} --accept-dns
  - systemctl enable --now tailnet-pod-routing.service
%{endif}
%{if var.tailscale_auth_key != "" && var.tailnet_dns_zone != ""}
  - /usr/local/sbin/tailnet-dns-apply.sh ${var.tailnet_dns_zone}
%{endif}
EOF

  meta_data = yamlencode({
    instance-id    = var.vm_name
    local-hostname = var.vm_name
  })
}

# ============================================================
# VM definition
# ============================================================
resource "proxmox_virtual_environment_vm" "this" {
  name      = var.vm_name
  node_name = var.pm_node

  description = <<-EOF
AstroLumina RKE2 ${var.environment} node — generated by modules/qm_vm
Environment : ${var.environment}
Tags        : ${join(", ", [for k, v in local.common_labels : "${k}=${v}"])}
EOF

  # Compute / memory
  cores = var.vcpu
  sockets   = 1
  cpu = "host"
  memory = {
    dedicated = var.memory_mb
  }

  # Disks
  disk {
    interface = "scsi0"
    size      = var.disk_gb
    storage   = var.pm_storage
    discard   = "on"
    ssd       = true
  }

  # Cloud-init disk attached as IDE CD
  cdrom {
    interface = "ide2"
    image_id  = proxmox_cloud_init_disk.this.id
  }

  # Network – single NIC; MAC is optional.
  network {
    bridge     = var.pm_network_bridge
    model      = "virtio"
    vlan_label = ""
    mac_address = var.mac_address != "" ? var.mac_address : null
  }

  # Serial console
  serial {
    id   = 0
    type = "socket"
  }

  # Operating system
  operating_system {
    type = "l26"
  }

  # Cloud-init settings
  cloud_init_options {
    storage = var.pm_storage
  }

  # Ensure VM boots even without the CD (user-data comes from cloud-init disk)
  boot = "order=scsi0;ide2"

  # Start immediately if requested
  started    = var.running
  stop_on_destroy = true

  # Timeout for operations
  timeouts {
    create = "30m"
    update = "10m"
    delete = "10m"
  }

  lifecycle {
    ignore_changes = [
      # Tags applied via the Proxmox UI should not be overwritten
      tags,
    ]
  }
}

# ============================================================
# Data source for IP – resolves via proxmox_virtual_environment_vm
# Reads the running config; falls back gracefully when stopped.
# ============================================================
data "proxmox_virtual_environment_vm" "current" {
  count   = var.running ? 1 : 0
  node_name = var.pm_node
  vm_id   = proxmox_virtual_environment_vm.this.vm_id
}

# Extract the primary IPv4 from the running config. With static IPs the
# address appears in network[0].ipv4[0].address; with DHCP it may be
# absent until the lease is handed out (then proxmox reads it from the
# guest agent once available). Returns null when the VM is stopped.
locals {
  # Prefer explicit static IP when the caller asked for one (the data
  # source can lag behind boot). Fall back to what Proxmox reports.
  resolved_ip = var.ipv4_address != "" ? split("/", var.ipv4_address)[0] : (
    can(data.proxmox_virtual_environment_vm.current[0].network[0].ipv4[0].address)
    ? data.proxmox_virtual_environment_vm.current[0].network[0].ipv4[0].address
    : "pending"
  )
}

# ============================================================
# Outputs
# ============================================================
output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = var.vm_name
}

output "ip_address" {
  description = "Primary IPv4 address of the VM"
  value       = local.resolved_ip
}

output "vcpu" {
  description = "Number of CPUs"
  value       = var.vcpu
}

output "memory_mb" {
  description = "Memory in MB"
  value       = var.memory_mb
}

output "disk_gb" {
  description = "Disk size in GB"
  value       = var.disk_gb
}

output "environment" {
  description = "Deployment environment this VM belongs to"
  value       = var.environment
}

output "labels" {
  description = "Effective env/role/cluster labels (caller tags merged with Environment)"
  value       = local.common_labels
}

output "mac_address" {
  description = "Effective MAC address (auto-generated when not supplied)"
  value       = proxmox_virtual_environment_vm.this.network[0].mac_address
}
