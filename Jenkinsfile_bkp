pipeline {
    agent any
    
    environment {
        // Java environment
        JAVA_HOME = tool 'JDK17'  // Ensure JDK17 is configured in Jenkins Global Tools
        MAVEN_HOME = tool 'Maven3'  // Ensure Maven is configured in Jenkins Global Tools
        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"
        
        // Terraform environment
        TF_VERSION = '1.5.7'  // Specify Terraform version
        TF_INPUT = 'false'
        TF_IN_AUTOMATION = 'true'
        
        // AWS credentials (if using AWS)
        AWS_DEFAULT_REGION = 'ap-south-2'
        
        // Application settings
        APP_NAME = 'c3ops-springboot-mysql-app'
        ARTIFACT_VERSION = "${env.BUILD_NUMBER}"
    }
    
    tools {
        jdk 'JDK17'
        maven 'Maven3'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
                
                // Display build information
                sh '''
                    echo "=== Build Information ==="
                    echo "Java Version: $(java -version 2>&1 | head -1)"
                    echo "Maven Version: $(mvn -version | head -1)"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Workspace: ${WORKSPACE}"
                '''
            }
        }
        
        stage('Java - Test') {
            steps {
                echo 'Running Java unit tests...'
                sh '''
                    mvn clean test -Dspring.profiles.active=test
                '''
            }
            post {
                always {
                    // Publish test results
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                    
                    // Archive test reports
                    archiveArtifacts artifacts: 'target/surefire-reports/*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Java - Build') {
            steps {
                echo 'Building Java application...'
                sh '''
                    mvn clean package -DskipTests=true
                    
                    # Verify the JAR was created
                    ls -la target/
                    
                    # Display JAR information
                    if [ -f target/${APP_NAME}-*.jar ]; then
                        echo "JAR file created successfully:"
                        ls -lh target/${APP_NAME}-*.jar
                    else
                        echo "ERROR: JAR file not found!"
                        exit 1
                    fi
                '''
            }
            post {
                success {
                    // Archive the built JAR
                    archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: false
                }
            }
        }
        
        stage('Java - Security Scan') {
            steps {
                echo 'Running security vulnerability scan...'
                sh '''
                    mvn org.owasp:dependency-check-maven:check \
                        -DfailBuildOnCVSS=7 \
                        -Dformats=HTML,XML
                '''
            }
            post {
                always {
                    // Archive security reports
                    archiveArtifacts artifacts: 'target/dependency-check-report.*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Terraform - Install') {
            steps {
                echo 'Installing Terraform...'
                sh '''
                    # Check if Terraform is already installed with correct version
                    if command -v terraform &> /dev/null; then
                        CURRENT_VERSION=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || terraform version | head -1 | cut -d' ' -f2 | sed 's/v//')
                        if [ "$CURRENT_VERSION" = "$TF_VERSION" ]; then
                            echo "Terraform $TF_VERSION is already installed"
                            terraform version
                            exit 0
                        fi
                    fi
                    
                    # Install Terraform
                    echo "Installing Terraform $TF_VERSION..."
                    wget -q https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
                    unzip -o terraform_${TF_VERSION}_linux_amd64.zip
                    chmod +x terraform
                    sudo mv terraform /usr/local/bin/ || mv terraform ~/bin/ || echo "Could not move terraform to system path"
                    
                    # Verify installation
                    terraform version
                '''
            }
        }
        
        stage('Terraform - Validate') {
            steps {
                echo 'Validating Terraform configuration...'
                dir('infra/terraform') {
                    sh '''
                        terraform init -backend=false
                        terraform validate
                        terraform fmt -check=true -diff=true
                    '''
                }
            }
        }
        
        stage('Terraform - Plan') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                echo 'Planning Terraform changes...'
                dir('infra/terraform') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-credentials'  // Configure this in Jenkins
                        ]
                    ]) {
                        sh '''
                            # Initialize Terraform
                            terraform init
                            
                            # Create execution plan
                            terraform plan \
                                -var="app_version=${BUILD_NUMBER}" \
                                -var="app_jar_name=${APP_NAME}-${BUILD_NUMBER}.jar" \
                                -out=tfplan \
                                -detailed-exitcode
                            
                            # Save plan output for review
                            terraform show -no-color tfplan > tfplan.txt
                        '''
                    }
                }
            }
            post {
                always {
                    // Archive Terraform plan
                    archiveArtifacts artifacts: 'infra/terraform/tfplan*', allowEmptyArchive: true
                }
            }
        }
        
        stage('Terraform - Apply') {
            when {
                allOf {
                    anyOf {
                        branch 'main'
                        branch 'master'
                    }
                    not { 
                        changeRequest() 
                    }
                }
            }
            steps {
                echo 'Applying Terraform changes...'
                
                // Add manual approval for production deployments
                script {
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        timeout(time: 10, unit: 'MINUTES') {
                            input message: 'Approve Terraform Apply to Production?', 
                                  parameters: [
                                      choice(
                                          name: 'ACTION',
                                          choices: ['apply', 'abort'],
                                          description: 'Choose whether to apply the Terraform plan'
                                      )
                                  ]
                        }
                    }
                }
                
                dir('infra/terraform') {
                    withCredentials([
                        [
                            $class: 'AmazonWebServicesCredentialsBinding',
                            credentialsId: 'aws-credentials'
                        ]
                    ]) {
                        sh '''
                            # Apply the plan
                            terraform apply -auto-approve tfplan
                            
                            # Output the results
                            terraform output -json > terraform-outputs.json
                            terraform output
                        '''
                    }
                }
            }
            post {
                always {
                    // Archive Terraform outputs
                    archiveArtifacts artifacts: 'infra/terraform/terraform-outputs.json', allowEmptyArchive: true
                }
            }
        }
        
        stage('Deploy Application') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo 'Deploying Spring Boot application...'
                script {
                    dir('infra/terraform') {
                        sh '''
                            # Get infrastructure outputs
                            if [ -f terraform-outputs.json ]; then
                                echo "Infrastructure outputs:"
                                cat terraform-outputs.json
                                
                                # Extract deployment information (customize based on your Terraform outputs)
                                # APP_SERVER_IP=$(jq -r '.app_server_public_ip.value' terraform-outputs.json)
                                # DATABASE_ENDPOINT=$(jq -r '.database_endpoint.value' terraform-outputs.json)
                                
                                echo "Application deployed with build number: ${BUILD_NUMBER}"
                            else
                                echo "No Terraform outputs found - skipping application deployment"
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('Health Check') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                }
            }
            steps {
                echo 'Performing application health check...'
                script {
                    // Add your application health check logic here
                    sh '''
                        # Example health check - customize based on your application
                        echo "Health check would be performed here"
                        echo "You could check application endpoints, database connectivity, etc."
                        
                        # Example: curl -f http://your-app-endpoint/actuator/health
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up workspace...'
            
            // Clean up temporary files
            sh '''
                # Clean Maven target directory (optional)
                # mvn clean
                
                # Remove Terraform temporary files
                rm -f infra/terraform/.terraform.lock.hcl
                rm -rf infra/terraform/.terraform/
                rm -f terraform_*.zip
            '''
            
            // Archive build logs
            archiveArtifacts artifacts: 'build.log', allowEmptyArchive: true
        }
        
        success {
            echo 'Pipeline completed successfully!'
            
            // Send success notifications (customize as needed)
            emailext (
                subject: "✅ Build Success: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    Build completed successfully!
                    
                    Project: ${env.JOB_NAME}
                    Build Number: ${env.BUILD_NUMBER}
                    Branch: ${env.BRANCH_NAME}
                    
                    View build details: ${env.BUILD_URL}
                """,
                recipientProviders: [developers(), requestor()]
            )
        }
        
        failure {
            echo 'Pipeline failed!'
            
            // Send failure notifications
            emailext (
                subject: "❌ Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: """
                    Build failed!
                    
                    Project: ${env.JOB_NAME}
                    Build Number: ${env.BUILD_NUMBER}
                    Branch: ${env.BRANCH_NAME}
                    
                    View build details: ${env.BUILD_URL}
                    Console Output: ${env.BUILD_URL}console
                """,
                recipientProviders: [developers(), requestor()]
            )
        }
        
        unstable {
            echo 'Pipeline completed with warnings!'
        }
    }
}