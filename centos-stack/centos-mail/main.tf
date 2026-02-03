# --- Storage Configuration ---
resource "libvirt_volume" "mail_disk" {
  name = "mail-disk.qcow2" # Unique disk name
  pool = "default"
  size = 21474836480
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_mail" {
  name   = "centos-mail"
  memory = "2048" # 2GB Optimized
  vcpu   = 1

  cpu {
    mode = "host-passthrough"
  }

  kernel    = var.boot_from_kernel ? "../../OS_Resources/vmlinuz-c9" : null
  initrd    = var.boot_from_kernel ? "../../OS_Resources/initrd-c9.img" : null
  arguments = var.boot_from_kernel ? "console=tty0 console=ttyS0,115200n8 inst.ks=hd:LABEL=OEMDRV:/ks.cfg" : null

  boot_device {
    dev = ["hd", "cdrom"]
  }

  disk {
    volume_id = libvirt_volume.mail_disk.id
  }
  disk {
    file = "../../OS_Resources/CentOS-9-DVD.iso"
  }
  disk {
    file = "${path.module}/ksdata-centos-mail.iso"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # Standard Graphics (Console access)
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

output "mail_server_ip" {
  value = length(libvirt_domain.centos_mail.network_interface[0].addresses) > 0 ? libvirt_domain.centos_mail.network_interface[0].addresses[0] : "Waiting for IP..."
}
