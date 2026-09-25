#!/usr/bin/env bash
 set -euo pipefail
 cd "$(dirname "$0")/.."
 ip=$(terraform -chdir=terraform output -raw instance_ip)
 printf '[web]
%s ansible_user=ec2-user ansible_ssh_common_args="-o StrictHostKeyChecking=accept-new"
' "$ip" > ansible/inventory.ini
 echo "Created ansible/inventory.ini"
