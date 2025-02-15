#!/bin/bash

# Step 1: Clone the repository
git clone infra repo
cd Monithor-Work/infra/tf

# Step 2: Change key_name and key_path in the terraform.tfvars file
# Note: Replace <key_name_value> and <key_path_value> with actual values
sed -i 's/key_name = "old_value"/key_name = "<key_name_value>"/' terraform.tfvars
sed -i 's/key_path = "old_value"/key_path = "<key_path_value>"/' terraform.tfvars

# Step 3: Navigate to the tf directory
cd /Monithor-Work/infra/tf

# Step 4: Run terraform commands
terraform init
terraform plan
terraform apply -auto-approve

# Step 5: Ensure ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "Ansible is not installed. Please install ansible and rerun this script."
    exit 1
fi

# Step 6: Navigate to the ansible directory
cd ../ansible

# Step 7: Run the ansible-playbook command
ansible-playbook -i inventory.yaml playbook.yaml

# Step 8: Navigate to the Jenkins UI (Manual step)
echo "Please navigate to the Jenkins UI and select the 'MoniThorDeployment' job."

# Step 9: Instructions for Jenkins
echo "In the Jenkins UI, select the 'MoniThorDeployment' job and click on 'Build Now'."
echo "Wait for the job to finish running. The job will deploy the infrastructure to the prod nodes."
