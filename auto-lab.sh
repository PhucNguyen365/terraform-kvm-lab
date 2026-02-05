#!/bin/bash

# Stop script immediately if any command fails
set -e

echo "STARTING AUTOMATION PIPELINE (DESTROY & REBUILD)"

# --- PART 1: CLEANUP ---
echo "Cleaning up old environment..."

# Function to destroy Terraform resources
destroy_vm() {
    DIR=$1
    if [ -d "$DIR" ]; then
        echo "   -> Destroying resources in $DIR..."
        cd $DIR
        # Try to destroy; ignore errors if state doesn't exist
        terraform destroy -auto-approve 2>/dev/null || true
        # Remove Terraform state, cache, and lock files
        rm -rf .terraform .terraform.lock.hcl terraform.tfstate terraform.tfstate.backup
        cd - > /dev/null
    fi
}

# Destroy VMs sequentially
destroy_vm "centos-stack/centos-web"
destroy_vm "centos-stack/centos-mail"
destroy_vm "centos-stack/centos-dns"

echo "Removing old Packer build artifacts..."
rm -rf packer_build/output-*

# --- PART 2: BUILD GOLDEN IMAGE (PACKER) ---
echo "STARTING PACKER IMAGE BUILD"

# Build
echo "   -> Building ALL Images (Minimal & GUI) from image.pkr.hcl..."
cd packer_build
packer build -force image.pkr.hcl

cd ..

# --- PART 3: INFRASTRUCTURE DEPLOYMENT (TERRAFORM) ---
echo "PROVISIONING INFRASTRUCTURE WITH TERRAFORM"

deploy_vm() {
    DIR=$1
    NAME=$2
    echo "   -> Deploying $NAME..."
    cd $DIR
    terraform init > /dev/null  # Silent init to keep output clean
    terraform apply -auto-approve
    cd - > /dev/null
}

# Deploy in parallel using background processes (&)
# Remove '&' if you want sequential deployment to save resources
deploy_vm "centos-stack/centos-web" "Web Server" &
deploy_vm "centos-stack/centos-mail" "Mail Server" &
deploy_vm "centos-stack/centos-dns" "DNS Server" &

# Wait for all background jobs to finish
wait

echo "ALL TASKS COMPLETED! LAB ENVIRONMENT IS READY"
echo "You can now SSH into your VMs without a password!"