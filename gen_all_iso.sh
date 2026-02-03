#!/bin/bash
# Script: Automated Kickstart ISO Generator for Lab Services

# Function to generate ISO
create_iso() {
    SERVICE=$1
    echo "--- Đang tạo ISO cho $SERVICE ---"
    cd centos-stack/$SERVICE
    genisoimage -output ksdata-$SERVICE.iso -volid OEMDRV -logical-block-size 2048 -joliet -rock ks.cfg
    cd ../..
}

# Execute for defined services
create_iso "centos-web"
create_iso "centos-mail"
create_iso "centos-dns"

echo "=== BUILD PROCESS COMPLETED ==="