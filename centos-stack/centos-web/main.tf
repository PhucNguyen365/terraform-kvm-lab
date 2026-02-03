# --- Storage Configuration ---
resource "libvirt_volume" "web_disk" {
  name = "web-disk.qcow2"
  pool = "default"
  size = 21474836480 # 20GB
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_web" {
  name   = "centos-web"
  memory = "4096" # 4GB for GUI
  vcpu   = 2

  cpu {
    mode = "host-passthrough"
  }

  # --- Smart Boot Logic ---
  # Only load kernel if boot_from_kernel is true (Install mode)
  kernel = var.boot_from_kernel ? "../../OS_Resources/vmlinuz-c9" : null
  initrd = var.boot_from_kernel ? "../../OS_Resources/initrd-c9.img" : null

  # Kernel arguments for installation
  arguments = var.boot_from_kernel ? "console=tty0 console=ttyS0,115200n8 inst.ks=hd:LABEL=OEMDRV:/ks.cfg" : null

  # Boot priority
  boot_device {
    dev = ["hd", "cdrom"]
  }

  # --- Disks ---
  # 1. Main OS Disk
  disk {
    volume_id = libvirt_volume.web_disk.id
  }

  # 2. Installer ISO (Shared Resource)
  disk {
    file = "../../OS_Resources/CentOS-9-DVD.iso"
  }

  # 3. Kickstart ISO (Local Artifact)
  disk {
    file = "${path.module}/ksdata-centos-web.iso"
  }

  # --- Network & Graphics ---
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  # Graphics for GUI (Spice/QXL)
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
