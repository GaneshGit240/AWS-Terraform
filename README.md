# AWS Terraform + Ansible Infrastructure
Lab architecture: internet -> public ALB across two availability zones -> one EC2 nginx server.
Terraform creates networking, security groups, an SSM IAM role, EC2 and ALB. Ansible installs nginx and deploys the page.
One instance is intentional: this lab is not highly available. HTTP only, no real customer data.

## Prerequisites
Bash (WSL2 on Windows), Terraform 1.6+, AWS CLI authenticated to your sandbox account, Ansible with the dnf module, an existing EC2 key pair in ap-south-1 and its private key.
AWS EC2, ALB and public IPv4 have costs. This is not guaranteed free; destroy the lab after use.

## Deploy
```bash
aws sts get-caller-identity
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit admin_cidr to your actual public IPv4/32 and key_name to your existing key pair.
terraform -chdir=terraform init
terraform -chdir=terraform fmt -recursive
terraform -chdir=terraform validate
terraform -chdir=terraform plan
terraform -chdir=terraform apply
bash scripts/inventory.sh
chmod 600 /path/to/your-key.pem
ansible-playbook -i ansible/inventory.ini ansible/site.yml --private-key /path/to/your-key.pem
curl "$(terraform -chdir=terraform output -raw app_url)/health.html"
```
The ALB is unhealthy until Ansible finishes, and needs a short time to pass its health checks.
Run the same playbook again and record its changed count to demonstrate idempotence.
Terraform state is local for this single-user lab. Commit the generated .terraform.lock.hcl; never commit state, private keys, or real tfvars.

## Diagnose
SSH timeout: check your current public IP, key pair, region, and instance status.
ALB 503: check target health, Ansible completion, nginx service, and the health endpoint.
Repeat `terraform plan` after apply to inspect drift; record real output.

## Cleanup
```bash
terraform -chdir=terraform destroy
```
Confirm destruction completes. The pre-existing EC2 key pair is not deleted.
Future extensions: private application subnets, HTTPS with ACM, Auto Scaling, remote state.
Reference: https://developer.hashicorp.com/terraform/tutorials/aws-get-started
