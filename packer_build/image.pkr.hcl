packer {
  required_plugins {
    # Dùng hàng chính hãng HashiCorp, không lo 404
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_checksum" {
  type    = string
  default = "none" 
}

locals {
  iso_url = "../OS_Resources/CentOS-9-DVD.iso" 
}

# --- SOURCE 1: MINIMAL (Đổi từ libvirt -> qemu) ---
source "qemu" "minimal" {
  accelerator = "kvm" # Vẫn dùng KVM cho nhanh
  
  vm_name     = "packer-centos9-min"
  memory      = 2048
  cpus        = 2

  qemuargs = [
    ["-cpu", "host"]
  ]
  
  iso_url      = local.iso_url
  iso_checksum = var.iso_checksum

  # Cấu hình ổ cứng QEMU
  disk_interface = "virtio"
  disk_size      = "20G"
  format         = "qcow2"
  
  # Network mặc định của QEMU (User mode) rất lành, tự có DHCP
  net_device     = "virtio-net"
  
  # Boot Command (Giữ nguyên)
  boot_wait    = "5s"
  boot_command = [
    "<up><wait><tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-min.cfg<enter>"
  ]
  
  http_directory = "."
  
  ssh_username   = "root"
  ssh_password   = "123456"
  ssh_timeout    = "20m"
  
  shutdown_command = "echo 'packer' | shutdown -P now"
  
  output_directory = "output-minimal"
  
  # Để false để chạy ngầm, true để hiện màn hình xem cho sướng
  headless = false
}

# --- SOURCE 2: GUI (Đổi từ libvirt -> qemu) ---
source "qemu" "gui" {
  accelerator = "kvm"
  
  vm_name     = "packer-centos9-gui"
  memory      = 4096
  cpus        = 2
  
  qemuargs = [
    ["-cpu", "host"]
  ]
  
  iso_url      = local.iso_url
  iso_checksum = var.iso_checksum

  disk_interface = "virtio"
  disk_size      = "20G"
  format         = "qcow2"
  
  net_device     = "virtio-net"

  boot_wait    = "5s"
  boot_command = [
    "<up><wait><tab> inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-gui.cfg<enter>"
  ]
  
  http_directory = "."
  
  ssh_username   = "root"
  ssh_password   = "123456"
  ssh_timeout    = "30m"
  
  shutdown_command = "echo 'packer' | shutdown -P now"
  output_directory = "output-gui"
  
  headless = false
}

# --- BUILD ---
build {
  # Lưu ý: Ở đây phải gọi là source.qemu.*
  sources = ["source.qemu.minimal", "source.qemu.gui"]
  
  provisioner "shell" {
    inline = [
      "dnf clean all",
      "rm -f /etc/machine-id",
      "touch /etc/machine-id"
    ]
  }
}