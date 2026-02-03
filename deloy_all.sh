#!/bin/bash
# Script: Auto Deploy All Infrastructure (Web -> Mail -> DNS)

deploy_service() {
    SERVICE=$1
    echo "=========================================="
    echo "START DEPLOYING: $SERVICE"
    echo "=========================================="
    
    if [ -d "centos-stack/$SERVICE" ]; then
        cd centos-stack/$SERVICE
        
        echo "--- Initializing Terraform ---"
        terraform init
        
        echo "--- Applying Configuration ---"
        terraform apply -var="boot_from_kernel=true" -auto-approve
        
        if [ $? -eq 0 ]; then
             echo "SUCCESS: $SERVICE is running."
        else
             echo "ERROR: Failed to deploy $SERVICE."
             exit 1
        fi
        
        cd ../..
    else
        echo "Folder not found: $SERVICE"
    fi
}

deploy_service "centos-web"
deploy_service "centos-mail"
deploy_service "centos-dns"

echo "ALL SERVICES DEPLOYED SUCCESSFULLY!