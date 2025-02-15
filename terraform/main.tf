# Configure the required AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure AWS provider with specified region
provider "aws" {
  region = var.aws_region
}

# Jenkins Master Instance
# Primary Jenkins server that manages the CI/CD pipeline
resource "aws_instance" "jenkins" {
  count         = 1  # Set to desired number of instances
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Name = "MoniThor-Jenkins-Master"
    Managed_By  = "Terraform"
  }
}

# Docker Agent Instance
# Agent that runs docker containers
resource "aws_instance" "docker" {
  count         = 1  # Set to desired number of instances 
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Name = "MoniThor-Docker-Agent"
    Managed_By  = "Terraform"
  }
}

# Ansible Agent Instance
# Agent that runs ansible containers
resource "aws_instance" "ansible" {
  count         = 1 # Set to desired number of instances
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Name = "MoniThor-Ansible-Agent"
    Managed_By  = "Terraform"
  }
}

# Monitoring Application Instances
# Production instances running the MoniThor monitoring application
resource "aws_instance" "monitoring_instances" {
  count         = 2  # Set to desired number of instances.
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  vpc_security_group_ids = [var.security_group_id]
  tags = {
    Name = "MoniThor-Prod-Instance-${count.index + 1}"
    Managed_By  = "Terraform"
  }
}

# Application Load Balancer
# Distributes incoming application traffic across multiple targets
resource "aws_lb" "MoniThor_app_lb" {
  name               = "MoniThor-application-lb"
  internal           = false  # Internet-facing load balancer
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets           = var.subnet_ids
  tags = {
    Name = "MoniThor-application-lb"
    Managed_By  = "Terraform"
  }
}

# Target Group
# Group of targets (EC2 instances) that the load balancer routes traffic to
resource "aws_lb_target_group" "MoniThor_app_tg" {
  name     = "MoniThor-app-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Health check configuration to monitor target health
  health_check {
    enabled             = true
    healthy_threshold   = 2    # Number of consecutive successful checks required
    interval            = 30   # Time between health checks (seconds)
    timeout             = 5    # Time to wait for a response (seconds)
    path                = "/"  # Health check endpoint
    unhealthy_threshold = 2    # Number of consecutive failed checks required
  }

  # Session stickiness configuration
  stickiness {
    type            = "lb_cookie"  # Load balancer-generated cookie
    cookie_duration = 86400        # Cookie validity period (24 hours)
    enabled         = true
  }
}

# Attach instances to target group
resource "aws_lb_target_group_attachment" "MoniThor_app_tg_attachment" {
  count            = 2  # Match the number of monitoring instances
  target_group_arn = aws_lb_target_group.MoniThor_app_tg.arn
  target_id        = aws_instance.monitoring_instances[count.index].id
  port             = 8080  # Port on which the monitoring application listens for incoming traffic
}

# Listener
# Defines how the load balancer should handle incoming requests
resource "aws_lb_listener" "MoniThor_app_listener" {
  load_balancer_arn = aws_lb.MoniThor_app_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"  # Forward requests to target group
    target_group_arn = aws_lb_target_group.MoniThor_app_tg.arn
  }
}

# Generate the Ansible inventory file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../ansible/inventory.yaml.tpl", {
    jenkins_master_ip = aws_instance.jenkins[0].public_ip
    docker_agent_ip   = aws_instance.docker[0].public_ip
    ansible_agent_ip  = aws_instance.ansible[0].public_ip
    monitoring_instances_ips = aws_instance.monitoring_instances[*].public_ip
    key_name         = "${var.key_path}/${var.key_name}.pem"
    ssh_user         = var.ssh_user
    load_balancer_dns = aws_lb.MoniThor_app_lb.dns_name
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}

# Generate the Ansible configuration file
resource "local_file" "ansible_cfg" {
  content = templatefile("${path.module}/../ansible/ansible.cfg.tpl", {
    inventory_file = "${path.module}/../ansible/inventory.yaml"
    remote_user = var.ssh_user
    private_key_file = "${var.key_path}${var.key_name}.pem"
    host_key_checking = false
  })
  filename = "${path.module}/../ansible/ansible.cfg"
}

# Run Ansible after inventory is created
resource "null_resource" "run_ansible" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${path.module}/../ansible/inventory.yaml ${path.module}/../ansible/main.yaml "
  }
}

output "jenkins_master_ip" {
  value = aws_instance.jenkins[0].public_ip
}

output "docker_agent_ip" {
  value = aws_instance.docker[0].public_ip
}

output "ansible_agent_ip" { 
  value = aws_instance.ansible[0].public_ip
}

output "monitoring_instances_ips" {
  value = aws_instance.monitoring_instances[*].public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins[0].public_ip}:8080"
}

output "Monithor-WebApp" {
  value = "http://${aws_lb.MoniThor_app_lb.dns_name}"
}

output "key_name" {
  value = var.key_name
}