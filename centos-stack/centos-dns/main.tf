# --- Storage Configuration ---
resource "libvirt_volume" "dns_disk" {
  name = "dns-disk.qcow2" # Unique disk name for DNS
  pool = "default"
  size = 21474836480 # 20GB
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_dns" {
  name   = "centos-dns"
  memory = "1024" # Optimized: 1GB RAM for Minimal Server
  vcpu   = 1

  cpu {
    mode = "host-passthrough"
  }

  # --- Boot Logic (Kernel/Initrd) ---
  # Only attach kernel/initrd during installation phase (boot_from_kernel = true)
  kernel = var.boot_from_kernel ? abspath("${path.module}/../../OS_Resources/vmlinuz-c9") : null
  initrd = var.boot_from_kernel ? abspath("${path.module}/../../OS_Resources/initrd-c9.img") : null

  # --- Kernel Arguments (CMDLINE) ---
  # FIX: Using List of Maps for provider v0.7.6 compatibility.
  # This ensures 'console' arguments are not merged/overwritten.
  cmdline = var.boot_from_kernel ? [
    { "console" = "tty0" },
    { "console" = "ttyS0,115200n8" },         # Serial console for troubleshooting
    { "inst.ks" = "hd:LABEL=OEMDRV:/ks.cfg" } # Kickstart file location
  ] : []

  # Boot priority order
  boot_device {
    dev = ["hd", "cdrom"]
  }

  # --- Disks ---
  # 1. Main OS Disk
  disk {
    volume_id = libvirt_volume.dns_disk.id
  }

  # 2. Installer ISO (Shared Resource)
  disk {
    file = abspath("${path.module}/../../OS_Resources/CentOS-9-DVD.iso")
  }

  # 3. Kickstart ISO (Local generated artifact)
  disk {
    file = abspath("${path.module}/ksdata-centos-dns.iso")
  }

  # --- Network ---
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # --- Graphics & Console ---
  console {
    type        = "pty"
    target_port = "0"
  }

  graphics {
    type        = "spice"
    autoport    = true
    listen_type = "address"
  }
}

# --- Outputs ---
output "dns_server_ip" {
  value = length(libvirt_domain.centos_dns.network_interface[0].addresses) > 0 ? libvirt_domain.centos_dns.network_interface[0].addresses[0] : "Waiting for IP..."
}
