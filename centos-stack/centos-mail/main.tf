# --- Storage Configuration ---
resource "libvirt_volume" "mail_disk" {
  name   = "mail-disk.qcow2" # Unique disk name for Mail
  pool   = "default"
  source = abspath("${path.module}/../../packer_build/output-minimal/packer-centos9-min")
  format = "qcow2"
  # size = 21474836480 # 20GB
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_mail" {
  name   = "centos-mail"
  memory = "2048" # 2GB RAM for Postfix/Dovecot
  vcpu   = 1

  cpu {
    mode = "host-passthrough"
  }

  # --- EFI Configuration ---
  #firmware = "/usr/share/OVMF/OVMF_CODE_4M.fd"

  # --- Disks ---
  disk {
    volume_id = libvirt_volume.mail_disk.id
  }
  # disk {
  #   file = abspath("${path.module}/../../OS_Resources/CentOS-9-DVD.iso")
  # }
  # disk {
  #   file = abspath("${path.module}/ksdata-centos-mail.iso")
  # }

  # --- Network ---
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  video {
    type = "virtio"
  }

  # --- Graphics & Console ---
  console {
    type        = "pty"
    target_type = "serial"
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
