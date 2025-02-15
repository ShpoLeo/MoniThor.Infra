# MoniThor.Infra
My MoniThor App infrastructure repository.

## SOP for running the infrastructure

1. Ensure you have Ansible installed on your machine.
2. Clone the repository "app repo".
3. Navigate to the **/Monithor-Work/infra/ansible** directory.
4. Create **.env** and **hub.cfg** files with the following variables we send in the assignment.
5. Navigate to the **/Monithor-Work/infra/tf** directory
6. Change the **"key_name"** and **"key_path"** variables in the **terraform.tfvars** file.
7. Run the following commands one by one:
    ```
    terraform init
    ```
    ```
    terraform plan
    ```
    ```
    terraform apply
    ```
    Wait for Terraform and Ansible to finish provisioning and configuring the infrastructure.

8. Navigate to the Jenkins UI. (The URL will be printed after running the Ansible playbook.)

9. Select the **"MoniThorDeployment"** job and click on **"Build Now"**.
Wait for the job to finish running.

10. Connect to the lb DNS and start using **Monithor-WebApp**. (The URL will be printed after running the Ansible playbook.)