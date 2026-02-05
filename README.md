# 🛠️ IaC lab environment on KVM using Terraform and Packer

This project automates a CentOS 9 Lab environment (Web, Mail, DNS) using Packer for image building and Terraform for infrastructure provisioning on KVM/libvirt.

## ❗ Prerequisites & Permissions

Before execution, you must ensure the qemu-libvirt user has permission to read the ISO files from your home directory.

1. Grant Access using ACL

Instead of changing ownership of your home directory, use Access Control Lists (ACL) to grant limited access:

## ⚠️ **Hypervisor User Note**

This lab is tested on **Ubuntu**, where libvirt runs as:
`libvirt-qemu`  

On **CentOS/RHEL**, the user is usually:
`qemu`  

Check yours with:
```bash
grep -E 'user|group' /etc/libvirt/qemu.conf
```

### Allow hypervisor to traverse parent directories

```bash
sudo setfacl -m u:libvirt-qemu:rx /home/technical
sudo setfacl -m u:libvirt-qemu:rx /home/technical/ISO_Library
```

### Allow hypervisor to read the ISO file

```bash
sudo setfacl -m u:libvirt-qemu:r /home/technical/ISO_Library/CentOS-Stream-9-20260105.0-x86_64-dvd1.iso
```

2. Setup Resource Symlink

To keep the project portable, use a symbolic link instead of copying large ISO files:

```bash
mkdir -p OS_Resources
ln -s /home/technical/ISO_Library/CentOS-Stream-9-20260105.0-x86_64-dvd1.iso OS_Resources/CentOS-9-DVD.iso
```

## 🏗️ Manual Deployment (Step-by-Step)

Executing manually is recommended for the first run to understand the workflow.
Step 1: Build Golden Images with Packer

Packer creates .qcow2 disk images with pre-configured SSH keys and OS settings.

```bash
cd packer_build
packer build -force image.pkr.hcl
cd ..
```

Result: output-minimal/ and output-gui/ directories containing the artifacts.
Step 2: Provision Infrastructure with Terraform

Each service is decoupled into its own directory to maintain independent state files.

Web Server (GUI Image):

```bash
cd centos-stack/centos-web
terraform init && terraform apply -auto-approve
```

Mail & DNS Servers (Minimal Image):

```bash
cd ../centos-mail && terraform init && terraform apply -auto-approve
cd ../centos-dns && terraform init && terraform apply -auto-approve
```

## 🔑 SSH Access

Passwordless SSH is enabled by default. Once deployed, access your VMs via:

```bash
ssh root@<PROVISIONED_IP>
```

## 🧹 Cleanup

To wipe the environment and reset the state:

### Destroy individual components

```bash
terraform destroy -auto-approve
```

### OR use the cleanup script to wipe everything

```bash
chmod +x clean-lab.sh
./clean-lab.sh
```

## 🎁 Bonus: One-Click Automation

Once you are familiar with the manual steps, use the integrated script for rapid rebuilding:

### This script automates: Destroy -> Build -> Parallel Deploy

```bash
chmod +x auto-lab.sh
./auto-lab.sh
```

## 📁 File Structure

```
terraform-kvm-lab/
│
├── README.md            # Project documentation and usage guide
│
├── auto-lab.sh          # End-to-end automation: Destroy → Build → Deploy
├── clean-lab.sh         # Cleans the lab and removes Terraform/Packer artifacts
│
├── OS_Resources/        # Contains symlink to OS installation media (ISO)
│   └── CentOS-9-DVD.iso -> /home/technical/ISO_Library/...
│
├── packer_build/        # Image build pipeline (Golden Images)
│   ├── image.pkr.hcl    # Main Packer template definition
│   ├── ks-min.cfg       # Kickstart file for minimal OS image
│   └── ks-gui.cfg       # Kickstart file for GUI-enabled OS image
│
└── centos-stack/        # Terraform infrastructure modules
    ├── centos-web/      # Web server infrastructure (GUI image)
    │   ├── main.tf      # VM resources, disks, network config
    │   └── provider.tf  # libvirt provider configuration
    │
    ├── centos-mail/     # Mail server infrastructure (Minimal image)
    │   ├── main.tf
    │   └── provider.tf
    │
    └── centos-dns/      # DNS server infrastructure (Minimal image)
        ├── main.tf
        └── provider.tf
```
