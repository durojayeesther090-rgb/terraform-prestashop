terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(pathexpand(var.public_key_path))
}

resource "aws_security_group" "prestashop_sg" {
  name        = "prestashop-sg"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "prestashop" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.prestashop_sg.id]

  root_block_device {
    volume_size = 20
  }

  tags = {
    Name = "prestashop-server"
  }
}

# Dynamic provisioning: generate the Ansible inventory from the new VM's IP
resource "local_file" "ansible_inventory" {
  content  = <<-EOT
    [prestashop]
    ${aws_instance.prestashop.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/prestashop-key ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
  filename = "${path.module}/inventory.ini"
}

# Run Ansible automatically after the VM is created
resource "null_resource" "run_ansible" {
  depends_on = [aws_instance.prestashop, local_file.ansible_inventory]

  provisioner "local-exec" {
    command = <<-EOT
      sleep 60
      ansible-playbook -i inventory.ini playbook.yml
    EOT
  }
}
