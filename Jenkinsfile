pipeline {
    agent any
    stages {
        stage('Bash Work') {
            steps {
                echo 'Running script'
                sh '''
                cd ./project
                ls -la 
                chmod +x scripts/parse_text.sh
                cd ./scripts
                ./parse_text.sh arg1 arg2 
                cd ../..
                '''
            }
        }
        stage('Login to Registry') {
            steps {
                script {
                    env.REGISTRY = "registry.devops:5000"
                    env.GIT_HASH = sh(returnStdout: true, script: 'cd ./project && git rev-parse --short HEAD').trim()
                }
                withCredentials([usernamePassword(credentialsId: 'registry-data', 
                usernameVariable: 'REG_USER',
                passwordVariable: 'REG_PASS')]) {
                    sh 'docker login registry.devops:5000 -u $REG_USER -p $REG_PASS'
                }
            }
        }
        stage('Build Images') {
            steps {
                script {
                    GIT_HASH = sh(returnStdout: true, script: 'cd ./project && git rev-parse --short HEAD').trim()

                    echo "Building nginx image with tag: $GIT_HASH"
                    sh """
                        cd ./project
                        docker build -t registry.devops:5000/nginx:$GIT_HASH containers/nginx
                        docker push registry.devops:5000/nginx:$GIT_HASH

                        docker build -t registry.devops:5000/drupal:$GIT_HASH containers/drupal
                        docker push registry.devops:5000/drupal:$GIT_HASH
                        
                    """
                }
            }
        }
        stage('Deploy') {
            environment {
                VERSION_TAG = "${GIT_HASH}"
            }
            steps {
                sh '''
                echo "Deploying containers"
                cd ./project/containers
                
                echo "VERSION_TAG=$GIT_HASH" > .env

                
                docker compose --env-file .env up -d

                echo "Set write permissions for Drupal installer"
                docker exec drupal chmod 664 /opt/drupal/web/sites/default/settings.php
                docker exec drupal chown www-data:www-data /opt/drupal/web/sites/default/settings.php

                echo "After installation you can revert permissions manually"
                cd ../..
                '''
                // # docker exec drupal chmod 444 /opt/drupal/web/sites/default/settings.php
            }
        }
        stage('Testing') {
            steps {
                sh '''
                echo "Create test file in Nginx container"
                docker exec -i nginx sh -c "echo 'test content' > /opt/html/upload/test.txt"

                echo "Go to scripts folder"
                cd ./project/scripts

                echo "Connect Jenkins to devops network if needed"
                # docker network connect containers_devops jenkins || echo "already connected to devops network"

                echo "Run parse_text.sh script"
                ./parse_text.sh https://nginx.devops upload/test.txt 

                echo "Curl test ignoring self-signed certificate"
                curl -k https://nginx.devops/dp/

                echo "Disconnect Jenkins from devops network"
                # docker network disconnect containers_devops jenkins
                cd ../..
                '''
            }
        }
        stage('Ansible works') {
            steps {
                sh '''
                cd ./Ansible
                ls -la ./playbooks
                
                ansible-playbook \
                -i inventories/server/hosts \
                playbooks/drupal.yml \
                --become \
                --extra-vars "
                    drupal_compose_state=present
                    nginx_user: "yes_admin"
                    nginx_password: "yes_admin"
                " 
                    
                sudo docker --version
                '''
            }
        }    
    }
}