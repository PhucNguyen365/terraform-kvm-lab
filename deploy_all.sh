#!/bin/bash
# Script: PhucOps Smart Deployer (Fixed for EFI & Sequential Install)

# Output file for storing server IP addresses for later use
IP_FILE="inventory_ips.txt"
echo "--- Server Inventory ---" > $IP_FILE

deploy_service() {
    SERVICE=$1
    # Ensure VM_NAME matches the domain name in libvirt
    VM_NAME="$SERVICE" 
    echo "=========================================="
    echo "START DEPLOYING: $SERVICE"
    echo "=========================================="
    
    # Verify if service directory exists
    if [ -d "centos-stack/$SERVICE" ]; then
        cd "centos-stack/$SERVICE" || exit
        
        echo "--- Initializing Terraform ---"
        terraform init
        
        echo "--- Phase 1: Installing OS (EFI Mode) ---"
        # Deploy VM using BIOS/EFI boot order (CDROM to HDD)
        terraform apply -auto-approve
        
        # Loop to monitor VM state; installation is complete when VM powers off
        echo "--- Waiting for $SERVICE to finish installation (Poweroff)... ---"
        while [ "$(virsh list --all | grep "$VM_NAME" | awk '{print $3}')" == "running" ]; do
            sleep 20
            echo -n "."
        done
        echo -e "\n$SERVICE installation finished."

        # --- Collect IP address ---
        # We need to get the IP from Terraform. 
        # Since your output variable in main.tf is 'centos_web_server_ip'
        # we manually specify the variable name here for clarity.
        if [ "$SERVICE" == "centos-web" ]; then
            IP=$(terraform output -raw centos_web_server_ip)
        elif [ "$SERVICE" == "centos-mail" ]; then
            IP=$(terraform output -raw mail_server_ip)
        elif [ "$SERVICE" == "centos-dns" ]; then
            IP=$(terraform output -raw dns_server_ip)
        fi

        # Save to file: centos-web | 192.168.122.xx
        echo "$SERVICE | $IP" >> "../../$IP_FILE"
        
        # Restart the VM to boot from the newly installed system on Disk
        echo "--- Starting $SERVICE from Hard Disk... ---"
        virsh start "$VM_NAME"
        
        cd ../..
    else
        echo "Directory not found: $SERVICE"
    fi
}

# Deploy services one by one to prevent Disk I/O bottlenecks
deploy_service "centos-web"
deploy_service "centos-mail"
deploy_service "centos-dns"

echo "=========================================="
echo "ALL SERVICES DEPLOYED SUCCESSFULLY!"