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
                    kubectl config current-context
                    kubectl get nodes
                    kubectl cluster-info
                    '''
                }
            }
        }

        stage('Clean Old Deployments') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG')]) {
                    bat '''
                    echo Limpiando deployments anteriores...
                    kubectl delete deployment --all --ignore-not-found=true
                    kubectl delete service --all --ignore-not-found=true
                    echo Esperando limpieza...
                    ping 127.0.0.1 -n 16 > nul
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG')]) {
                    bat '''
                    echo ========================================
                    echo PASO 0: Desplegando PostgreSQL
                    echo ========================================
                    kubectl apply -f k8s\\configmaps\\postgres-config.yaml
                    kubectl apply -f k8s\\secrets\\postgres-secret.yaml
                    kubectl apply -f k8s\\volumes\\postgres-pvc.yaml
                    kubectl apply -f k8s\\deployments\\postgres-deployment.yaml
                    kubectl apply -f k8s\\services\\postgres-service.yaml
                    echo Esperando 60 segundos para PostgreSQL...
                    ping 127.0.0.1 -n 61 > nul
                    kubectl get pods -l app=postgres
                    
                    echo.
                    echo ========================================
                    echo PASO 1: Desplegando Service Discovery
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\service-discovery-deployment.yaml
                    kubectl apply -f k8s\\services\\service-discovery-service.yaml
                    echo Esperando 60 segundos para Service Discovery...
                    ping 127.0.0.1 -n 61 > nul
                    
                    echo.
                    echo ========================================
                    echo PASO 2: Desplegando Microservicios Core
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\user-service-deployment.yaml
                    kubectl apply -f k8s\\deployments\\product-service-deployment.yaml
                    kubectl apply -f k8s\\deployments\\payment-service-deployment.yaml
                    kubectl apply -f k8s\\deployments\\order-service-deployment.yaml
                    
                    kubectl apply -f k8s\\services\\user-service-service.yaml
                    kubectl apply -f k8s\\services\\product-service-service.yaml
                    kubectl apply -f k8s\\services\\payment-service-service.yaml
                    kubectl apply -f k8s\\services\\order-service-service.yaml
                    
                    echo Esperando 60 segundos para microservicios...
                    ping 127.0.0.1 -n 61 > nul
                    kubectl get pods
                    
                    echo.
                    echo ========================================
                    echo PASO 3: Desplegando API Gateway
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\api-gateway-deployment.yaml
                    kubectl apply -f k8s\\services\\api-gateway-service.yaml
                    echo Esperando 30 segundos para API Gateway...
                    ping 127.0.0.1 -n 31 > nul
                    
                    echo.
                    echo ========================================
                    echo PASO 4: Desplegando Proxy Client
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\proxy-client-deployment.yaml
                    kubectl apply -f k8s\\services\\proxy-client-service.yaml
                    echo Esperando 30 segundos para Proxy Client...
                    ping 127.0.0.1 -n 31 > nul
                    
                    echo.
                    echo ========================================
                    echo ESTADO FINAL DEL CLUSTER
                    echo ========================================
                    kubectl get pods -o wide
                    echo.
                    kubectl get services
                    echo.
                    echo ========================================
                    echo Verificando health de los servicios
                    echo ========================================
                    kubectl get pods --field-selector=status.phase!=Running
                    '''
                }
            }
        }
    }

    post {
        always {
            bat 'docker logout || exit 0'
        }
        success {
            echo 'Deployment completed successfully!'
        }
        failure {
            echo 'Deployment failed. Check logs above.'
        }
    }
}
