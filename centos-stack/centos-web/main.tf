# --- Storage Configuration ---
resource "libvirt_volume" "web_disk" {
  name = "web-disk.qcow2"
  pool = "default"
  size = 21474836480 # 20GB
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_web" {
  name   = "centos-web"
  memory = "4096" # 4GB RAM for GUI performance
  vcpu   = 2

  cpu {
    mode = "host-passthrough"
  }

  # --- EFI Configuration ---
  firmware = "/usr/share/OVMF/OVMF_CODE_4M.fd"

  cmdline = [
    { "console" = "tty0" },
    { "console" = "ttyS0,115200n8" },
    { "inst.ks" = "hd:LABEL=OEMDRV:/ks.cfg" }
  ]

  # --- Disks ---
  disk {
    volume_id = libvirt_volume.web_disk.id
  }
  disk {
    file = abspath("${path.module}/../../OS_Resources/CentOS-9-DVD.iso")
  }
  disk {
    file = abspath("${path.module}/ksdata-centos-web.iso")
  }

  # --- Network ---
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # --- Graphics for GUI ---
  # QXL is required for decent GUI performance in KVM
  video {
    type = "qxl"
  }

  graphics {
    type        = "spice"
    autoport    = true
    listen_type = "address"
  }

  console {
    type        = "pty"
    target_port = "0"
  }
}

# --- Outputs ---
output "web_server_ip" {
  value       = length(libvirt_domain.centos_web.network_interface[0].addresses) > 0 ? libvirt_domain.centos_web.network_interface[0].addresses[0] : "IP not assigned yet"
  description = "The private IP address of the Web Server"
}
