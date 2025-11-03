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
                    echo Verificando conexion al cluster...
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
                    echo ========================================
                    echo Limpiando deployments anteriores...
                    echo ========================================
                    kubectl delete deployment --all --ignore-not-found=true
                    kubectl delete service --all --ignore-not-found=true
                    kubectl delete pvc --all --ignore-not-found=true
                    echo Esperando limpieza completa...
                    ping 127.0.0.1 -n 21 > nul
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG')]) {
                    bat '''
                    echo ========================================
                    echo PASO 0: Desplegando MySQL
                    echo ========================================
                    kubectl apply -f k8s\\volumes\\mysql-pvc.yaml
                    kubectl apply -f k8s\\deployments\\mysql-deployment.yaml
                    kubectl apply -f k8s\\services\\mysql-service.yaml
                    echo Esperando 90 segundos para MySQL...
                    ping 127.0.0.1 -n 91 > nul
                    
                    echo Verificando estado de MySQL:
                    kubectl get pods -l app=mysql
                    kubectl logs -l app=mysql --tail=30 || echo "MySQL aun no tiene logs"
                    
                    echo.
                    echo ========================================
                    echo PASO 1: Desplegando Service Discovery
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\service-discovery-deployment.yaml
                    kubectl apply -f k8s\\services\\service-discovery-service.yaml
                    echo Esperando 60 segundos para Service Discovery...
                    ping 127.0.0.1 -n 61 > nul
                    
                    echo Verificando estado de Service Discovery:
                    kubectl get pods -l app=service-discovery
                    kubectl logs -l app=service-discovery --tail=20 || echo "Service Discovery aun no tiene logs"
                    
                    echo.
                    echo ========================================
                    echo PASO 2: Desplegando Microservicios Core
                    echo ========================================
                    echo Desplegando User Service...
                    kubectl apply -f k8s\\deployments\\user-service-deployment.yaml
                    kubectl apply -f k8s\\services\\user-service-service.yaml
                    echo Esperando 45 segundos...
                    ping 127.0.0.1 -n 46 > nul
                    
                    echo Desplegando Product Service...
                    kubectl apply -f k8s\\deployments\\product-service-deployment.yaml
                    kubectl apply -f k8s\\services\\product-service-service.yaml
                    echo Esperando 45 segundos...
                    ping 127.0.0.1 -n 46 > nul
                    
                    echo Desplegando Payment Service...
                    kubectl apply -f k8s\\deployments\\payment-service-deployment.yaml
                    kubectl apply -f k8s\\services\\payment-service-service.yaml
                    echo Esperando 45 segundos...
                    ping 127.0.0.1 -n 46 > nul
                    
                    echo Desplegando Order Service...
                    kubectl apply -f k8s\\deployments\\order-service-deployment.yaml
                    kubectl apply -f k8s\\services\\order-service-service.yaml
                    
                    echo Esperando 90 segundos para que los microservicios se registren en Eureka...
                    ping 127.0.0.1 -n 91 > nul
                    
                    echo Estado actual de los microservicios:
                    kubectl get pods
                    
                    echo.
                    echo ========================================
                    echo PASO 3: Desplegando API Gateway
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\api-gateway-deployment.yaml
                    kubectl apply -f k8s\\services\\api-gateway-service.yaml
                    echo Esperando 60 segundos para API Gateway...
                    ping 127.0.0.1 -n 61 > nul
                    
                    echo.
                    echo ========================================
                    echo PASO 4: Desplegando Proxy Client
                    echo ========================================
                    kubectl apply -f k8s\\deployments\\proxy-client-deployment.yaml
                    kubectl apply -f k8s\\services\\proxy-client-service.yaml
                    echo Esperando 60 segundos para Proxy Client...
                    ping 127.0.0.1 -n 61 > nul
                    
                    echo.
                    echo ========================================
                    echo ESTADO FINAL DEL CLUSTER
                    echo ========================================
                    kubectl get pods -o wide
                    echo.
                    kubectl get services
                    echo.
                    echo ========================================
                    echo Pods con problemas (si los hay):
                    echo ========================================
                    kubectl get pods --field-selector=status.phase!=Running
                    echo.
                    echo ========================================
                    echo Eventos recientes:
                    echo ========================================
                    kubectl get events --sort-by=.metadata.creationTimestamp --field-selector type=Warning | Select-Object -Last 20
                    echo.
                    echo ========================================
                    echo Verificando registro en Eureka
                    echo ========================================
                    echo Para ver Eureka Dashboard ejecutar:
                    echo kubectl port-forward service/service-discovery 8761:8761
                    echo Luego abrir: http://localhost:8761
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig-dev', variable: 'KUBECONFIG')]) {
                    bat '''
                    echo ========================================
                    echo VERIFICACION DE SALUD DE SERVICIOS
                    echo ========================================
                    echo.
                    echo Esperando 60 segundos adicionales para estabilizacion...
                    ping 127.0.0.1 -n 61 > nul
                    echo.
                    echo Estado final de todos los pods:
                    kubectl get pods
                    echo.
                    echo Pods que no estan Running:
                    kubectl get pods --field-selector=status.phase!=Running --no-headers | findstr /V "Completed" || echo Todos los pods estan Running!
                    echo.
                    echo Servicios expuestos:
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
        success {
            echo '========================================='
            echo 'Deployment completed successfully!'
            echo '========================================='
            echo ''
            echo 'Comandos utiles:'
            echo '1. Ver Eureka Dashboard:'
            echo '   kubectl port-forward service/service-discovery 8761:8761'
            echo '   http://localhost:8761'
            echo ''
            echo '2. Ver API Gateway:'
            echo '   kubectl port-forward service/api-gateway 8080:8080'
            echo '   http://localhost:8080'
            echo ''
            echo '3. Ver logs de un servicio:'
            echo '   kubectl logs -f deployment/user-service'
            echo ''
            echo '4. Ver estado de pods:'
            echo '   kubectl get pods -w'
            echo '========================================='
        }
        failure {
            echo '========================================='
            echo 'Deployment failed!'
            echo '========================================='
            echo ''
            echo 'Para diagnosticar:'
            echo '1. Ver logs del ultimo pod fallido:'
            echo '   kubectl logs <pod-name>'
            echo ''
            echo '2. Ver eventos del cluster:'
            echo '   kubectl get events --sort-by=.metadata.creationTimestamp'
            echo ''
            echo '3. Describir un pod problematico:'
            echo '   kubectl describe pod <pod-name>'
            echo '========================================='
        }
    }
}
