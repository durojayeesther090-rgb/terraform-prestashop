# PrestaShop on AWS with Terraform and Ansible

Terraform provisions an Ubuntu 22.04 EC2 instance (variables for region and instance size),
generates an Ansible inventory dynamically, and runs an Ansible playbook that installs
Apache, PHP, MariaDB and PrestaShop 8.1.7.

## Files
- main.tf: provider, AMI lookup, key pair, security group, EC2 instance, dynamic inventory, Ansible trigger
- variables.tf: region, instance_type, key_name, public_key_path
- outputs.tf: public IP and PrestaShop URL
- playbook.yml: Ansible playbook (database, web server, PrestaShop)

## Usage
    terraform init
    terraform plan
    terraform apply

Open the prestashop_url output in a browser and finish the PrestaShop installer
(DB host localhost, DB name prestashop, user psuser).

Clean up with: terraform destroy
