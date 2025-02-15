pipeline {
    agent none
    
    environment {
        COMMIT_ID = ''
    }
    
    stages {
        stage('Docker Operations') {
            agent {
                label 'docker-agent'
            }
            stages {
                stage('Docker Hub Login') {
                    steps {
                        script {
                            def configFile = readFile('/home/ubuntu/jenkins_agent/hub.cfg').trim()
                            def config = [:]
                            configFile.split('\n').each { line ->
                                def (key, value) = line.split('=')
                                config[key] = value
                            }
                            sh """
                            sudo docker login -u ${config.DOCKERHUB_USERNAME} -p ${config.DOCKERHUB_PASSWORD}
                            """
                            echo "Docker Hub login successful"
                        }
                    }
                }

                stage('Clean Workspace') {
                    steps {
                        script {
                            cleanWs()
                            echo "Workspace cleaned."
                            sh '''
                            sudo docker rm -f $(sudo docker ps -a -q) || true
                            '''
                        }
                        echo "Docker containers removed."
                    }
                }

                stage('Clone repo') {
                    steps {
                        script {
                            // Clean the workspace completely
                            sh '''
                                sudo rm -rf *
                                sudo rm -rf .git
                            '''
                            
                            // Clone and setup
                            sh '''
                                sudo git clone https://github.com/MayElbaz18/MoniTHOR--Project.git .
                                sudo git checkout main
                            '''
                            
                            // Capture commit ID with explicit variable assignment
                            COMMIT_ID = sh(
                                returnStdout: true,
                                script: 'sudo git rev-parse HEAD'
                            ).trim()
                            
                            // Set environment variable explicitly
                            env.COMMIT_ID = COMMIT_ID
                            
                            echo "Environment COMMIT_ID: ${COMMIT_ID}"
                            
                            // Verify the commit ID was captured
                            if (!COMMIT_ID) {
                                error "Failed to get commit ID"
                            }
                        }
                    }
                }

                stage('Docker build & run - Monithor - WebApp image') {
                    steps {
                        script {
                            sh """
                            sudo docker build -t monithor:${COMMIT_ID} .
                            sudo docker run --network host -d -p 8080:8080 --name monithor_container monithor:${COMMIT_ID}
                            """
                        }
                    }
                }

                stage('Move .env file to dir') {
                    steps {
                        script {
                            sh """
                            sudo docker cp /root/.env monithor_container:/MoniTHOR--Project
                            """
                        }
                    }
                }

                stage('Docker build & run - Selenium image') {
                    steps {
                        dir('selenium') {
                            script {
                                sh """
                                sudo docker build -t selenium:${COMMIT_ID} .
                                sudo docker run -d --network host --name selenium_container selenium:${COMMIT_ID}
                                """
                            }
                        }
                    }
                }

                stage('Show Results - Selenium') {
                    steps {
                        script {
                            sh """
                            sudo docker logs -f selenium_container
                            """
                        }
                    }
                }

                stage('Check Requests In Monithor-WebApp') {
                    steps {
                        script {
                            sh """
                            sudo docker logs monithor_container
                            """
                        }
                    }
                }

                stage('Docker push to docker hub') {
                    steps {
                        script {
                            def configFile = readFile('/home/ubuntu/jenkins_agent/hub.cfg').trim()
                            def config = [:]
                            configFile.split('\n').each { line ->
                                def (key, value) = line.split('=')
                                config[key] = value
                            }
                            sh """
                            sudo docker tag monithor:${COMMIT_ID} ${config.DOCKERHUB_USERNAME}/monithor:${COMMIT_ID}
                            sudo docker push ${config.DOCKERHUB_USERNAME}/monithor:${COMMIT_ID}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Ansible Operations') {
            agent {
                label 'ansible-agent'
            }
            stages {
                stage('Docker Hub Login') {
                    steps {
                        script {
                            def configFile = readFile('/home/ubuntu/jenkins_agent/hub.cfg').trim()
                            def config = [:]
                            configFile.split('\n').each { line ->
                                def (key, value) = line.split('=')
                                config[key] = value
                            }
                            sh """
                            sudo docker login -u ${config.DOCKERHUB_USERNAME} -p ${config.DOCKERHUB_PASSWORD}
                            """
                            echo "Docker Hub login successful"
                        }
                    }
                }

                stage('Docker Hub Login + Deploy to prod nodes') {
                    steps {
                        script {
                            def configFile = readFile('/home/ubuntu/jenkins_agent/hub.cfg').trim()
                            def config = [:]
                            configFile.split('\n').each { line ->
                                def (key, value) = line.split('=')
                                config[key] = value
                            }                       
                            sh """
                                echo "Deploying using Ansible with Docker image tag: ${COMMIT_ID}"
                                cd /home/ubuntu/infra/ansible
                                ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory.yaml main.yaml \\
                                    --extra-vars '{\"docker_tag\":\"${COMMIT_ID}\",\"docker_hub_username\":\"${config.DOCKERHUB_USERNAME}\",\"docker_hub_password\":\"${config.DOCKERHUB_PASSWORD}\"}' \\
                            """
                            echo "Finished deployment on prod nodes"
                        }
                    }
                }
            }
        }
    }
}
