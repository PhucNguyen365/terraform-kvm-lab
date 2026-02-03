# --- Storage Configuration ---
resource "libvirt_volume" "dns_disk" {
  name = "dns-disk.qcow2" # Unique disk name
  pool = "default"
  size = 21474836480
}

# --- Domain Configuration ---
resource "libvirt_domain" "centos_dns" {
  name   = "centos-dns"
  memory = "1024" # 1GB Optimized
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
    volume_id = libvirt_volume.dns_disk.id
  }
  disk {
    file = "../../OS_Resources/CentOS-9-DVD.iso"
  }
  disk {
    file = "${path.module}/ksdata-centos-dns.iso"
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

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

output "dns_server_ip" {
  value = length(libvirt_domain.centos_dns.network_interface[0].addresses) > 0 ? libvirt_domain.centos_dns.network_interface[0].addresses[0] : "Waiting for IP..."
}
