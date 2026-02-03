# --- Storage Configuration ---
resource "libvirt_volume" "mail_disk" {
  name = "mail-disk.qcow2" # Unique disk name for Mail
  pool = "default"
  size = 21474836480 # 20GB
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_mail" {
  name   = "centos-mail"
  memory = "2048" # 2GB RAM for Postfix/Dovecot
  vcpu   = 1

  cpu {
    mode = "host-passthrough"
  }

  # --- Boot Logic ---
  kernel = var.boot_from_kernel ? abspath("${path.module}/../../OS_Resources/vmlinuz-c9") : null
  initrd = var.boot_from_kernel ? abspath("${path.module}/../../OS_Resources/initrd-c9.img") : null

  # --- Kernel Arguments (CMDLINE) ---
  # FIX: List of Maps format for v0.7.6
  cmdline = var.boot_from_kernel ? [
    { "console" = "tty0" },
    { "console" = "ttyS0,115200n8" },
    { "inst.ks" = "hd:LABEL=OEMDRV:/ks.cfg" }
  ] : []

  boot_device {
    dev = ["hd", "cdrom"]
  }

  # --- Disks ---
  disk {
    volume_id = libvirt_volume.mail_disk.id
  }
  disk {
    file = abspath("${path.module}/../../OS_Resources/CentOS-9-DVD.iso")
  }
  disk {
    file = abspath("${path.module}/ksdata-centos-mail.iso")
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
output "mail_server_ip" {
  value = length(libvirt_domain.centos_mail.network_interface[0].addresses) > 0 ? libvirt_domain.centos_mail.network_interface[0].addresses[0] : "Waiting for IP..."
}
