# kvm_vm -- single KVM virtual machine (libvirt)

Creates one libvirt domain from a base QCOW2 image, with a cloud-init ISO
attached for first-boot provisioning (user, SSH key, packages, optional
Tailscale join and 9p host-directory share).

## Usage

```hcl
module "vm" {
  source = "git::https://github.com/AstroLumina-Rise-n-Shine/AstroLumina-Terraform-Library.git//modules/kvm_vm?ref=main"

  vm_name         = "rke2-cp-01"
  vcpu            = 2
  memory_mb       = 4096
  disk_gb         = 40
  base_image_path = "/var/lib/libvirt/images/ubuntu-24.04.qcow2"
  ssh_pub_key     = "ssh-ed25519 AAAA..."
  mac_address     = "52:54:00:a1:b2:c3" # must match a DHCP reservation
  environment     = "development"
}
```

## Notes

- `environment` (required) plus `tags` are merged into one label set that
  is written into the guest at `/etc/astrolumina-environment` and exposed
  through the `labels` output. libvirt domains have no native tags, so this
  file is how you tell environments apart from inside the VM.

## Notes

- `mac_address` pins the guest to a libvirt DHCP reservation, which is how
  the VM gets a stable LAN IP. Empty string means "no reservation".
- `tailscale_auth_key` triggers the Tailscale install + join at first boot;
  pair it with `tailnet_dns_zone` on exactly one node per cluster to serve
  split-DNS for that zone. Every tailnet-joined VM also gets the
  `tailnet-pod-routing` unit, which steers tailnet-bound traffic to table 52
  (works around Calico's fwmark colliding with Tailscale policy routing;
  harmless on non-RKE2 VMs).
- `host_share_path` shares a host directory read-only via 9p (used for the
  Kubernetes manifests repo). The `mount_tag` must match between the domain
  definition and cloud-init, otherwise the guest mount fails at boot.

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `vm_name` | string | -- | Domain, disk and hostname (required) |
| `vcpu` | number | `2` | Virtual CPUs |
| `memory_mb` | number | `2048` | RAM in MB |
| `disk_gb` | number | `20` | OS disk size in GB |
| `network_name` | string | `"default"` | Libvirt network |
| `disk_pool` | string | `"default"` | Storage pool |
| `tags` | map(string) | `{}` | Extra labels merged with `Environment` |
| `environment` | string | -- | Env name, written into the guest (required) |
| `base_image_path` | string | -- | Base QCOW2 on the host (required) |
| `ssh_username` | string | `"ubuntu"` | SSH/sudo user |
| `ssh_pub_key` | string | -- | Public key (required) |
| `ssh_password` | string | `""` | Password (empty disables password auth) |
| `running` | bool | `false` | Start the domain after creation |
| `mac_address` | string | `""` | MAC for a DHCP reservation |
| `host_share_path` | string | `""` | Host dir shared read-only via 9p |
| `guest_mountpoint` | string | `"/mnt/k8s"` | Guest mount path |
| `mount_tag` | string | `"k8s_repo"` | 9p mount tag |
| `tailscale_auth_key` | string | `""` | Reusable Tailscale auth key |
| `tailnet_dns_zone` | string | `""` | Split-DNS zone served by dnsmasq |

## Outputs

| Name | Description |
|---|---|
| `vm_name`, `vcpu`, `memory_mb`, `disk_gb` | Echo of the sizing inputs |
| `ip_address` | First lease IP (`"N/A"` when stopped) |
| `environment` | Echo of the `environment` input |
| `labels` | Effective label set from the guest file |
