pipeline {
    agent any

    tools {
        jdk 'JDK11'
    }
    
    environment {
        REGISTRY = "docker.io/leonkhart"
        PROJECT_VERSION = "0.1.0"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'develop', url: 'https://github.com/LeonHartK/ecommerce-microservice-backend-app.git'
            }
        }

        stage('Build JARs') {
            steps {
                bat 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    def services = [
                        "api-gateway",
                        "service-discovery",
                        "order-service",
                        "product-service",
                        "payment-service",
                        "user-service",
                        "proxy-client"
                    ]
                    for (svc in services) {
                        bat """
                            echo Building Docker image for ${svc}
                            docker build -t %REGISTRY%/${svc}:dev --build-arg PROJECT_VERSION=%PROJECT_VERSION% ${svc}/
                        """
                    }
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'dockerhub-token', variable: 'DOCKER_TOKEN')]) {
                        bat """
                            echo %DOCKER_TOKEN% | docker login -u leonkhart --password-stdin
                        """
                        def services = [
                            "api-gateway",
                            "service-discovery",
                            "order-service",
                            "product-service",
                            "payment-service",
                            "user-service",
                            "proxy-client"
                        ]
                        for (svc in services) {
                            bat "docker push %REGISTRY%/${svc}:dev"
                        }
                    }
                }
            }
        }

        stage('Verify Cluster Connection') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG')]) {
                    bat '''
                    echo Verificando conexión con el cluster...
                    kubectl config current-context
                    kubectl get nodes
                    kubectl cluster-info
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG')]) {
                    bat '''
                    echo Desplegando microservicios en Kubernetes...
                    kubectl apply -f k8s\\deployments\\
                    kubectl apply -f k8s\\services\\
                    echo.
                    echo Esperando a que los pods estén listos...
                    timeout /t 10 /nobreak
                    kubectl get pods -o wide
                    kubectl get services
                    '''
                }
            }
        }
    }

    post {
        always {
            bat 'docker logout || exit 0'
        }
    }
}