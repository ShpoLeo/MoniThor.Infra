all:
  vars:
    ansible_ssh_private_key_file: ${key_name}
    ansible_user: ${ssh_user}
    jenkins_master_ip: ${jenkins_master_ip}
    ansible_python_interpreter: /usr/bin/python3
    load_balancer_dns: ${load_balancer_dns}
  children:
    jenkins:
      hosts:
        jenkins-master:
          ansible_host: ${jenkins_master_ip}
    docker:
      hosts:
        docker-agent:
          ansible_host: ${docker_agent_ip}
    ansible:
      hosts:
        ansible-agent:
          ansible_host: ${ansible_agent_ip}
    monitoring:
      hosts:
%{ for index, ip in monitoring_instances_ips ~}
        monitoring-${index + 1}:
          ansible_host: ${ip}
%{ endfor ~}
    servers:
      children:
        jenkins_servers:
        docker_agents:
        ansible_agents:
        monitoring: