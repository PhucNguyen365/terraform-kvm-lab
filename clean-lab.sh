#!/bin/bash
set -e

echo "CLEAN LAB"

destroy_vm() {
    DIR=$1
    [ -d "$DIR" ] || return
    echo "   -> Cleaning $DIR"
    cd "$DIR"
    terraform destroy -auto-approve 2>/dev/null || true
    rm -rf .terraform .terraform.lock.hcl terraform.tfstate*
    cd - > /dev/null
}

destroy_vm "centos-stack/centos-web"
destroy_vm "centos-stack/centos-mail"
destroy_vm "centos-stack/centos-dns"

echo "   -> Removing packer images"
rm -rf packer_build/output-*

echo "Done. Back to source-only state."
