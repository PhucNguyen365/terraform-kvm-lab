terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Biến điều khiển chế độ boot
variable "boot_from_kernel" {
  type    = bool
  default = false
}
