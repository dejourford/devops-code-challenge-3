pipeline {
    agent any

    environment {
        AWS_REGION   = 'us-east-2'
        ECR_REGISTRY = '149465511648.dkr.ecr.us-east-2.amazonaws.com'
        IMAGE_TAG    = "${env.GIT_COMMIT.take(7)}"
    }

    stages {
        stage('Build & Push Backend') {
            when {
                changeset "backend/**"
            }
            steps {
                dir('backend') {
                    sh "docker build --platform linux/amd64 -t ${ECR_REGISTRY}/tc2-dev-backend:${IMAGE_TAG} ."
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker push ${ECR_REGISTRY}/tc2-dev-backend:${IMAGE_TAG}"
                }
                withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh """
                        sed -i 's|${ECR_REGISTRY}/tc2-dev-backend:.*|${ECR_REGISTRY}/tc2-dev-backend:${IMAGE_TAG}|' k8s/backend-deployment.yaml
                        git config user.email "jenkins@ci"
                        git config user.name "Jenkins"
                        git add k8s/backend-deployment.yaml
                        git commit -m "ci: update backend image to ${IMAGE_TAG}"
                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/dejourford/devops-code-challenge-3.git main
                    """
                }
            }
        }

        stage('Build & Push Frontend') {
            when {
                changeset "frontend/**"
            }
            steps {
                dir('frontend') {
                    sh "docker build --platform linux/amd64 --build-arg REACT_APP_API_URL=/api -t ${ECR_REGISTRY}/tc2-dev-frontend:${IMAGE_TAG} ."
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker push ${ECR_REGISTRY}/tc2-dev-frontend:${IMAGE_TAG}"
                }
                withCredentials([usernamePassword(credentialsId: 'github-pat', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                    sh """
                        sed -i 's|${ECR_REGISTRY}/tc2-dev-frontend:.*|${ECR_REGISTRY}/tc2-dev-frontend:${IMAGE_TAG}|' k8s/frontend-deployment.yaml
                        git config user.email "jenkins@ci"
                        git config user.name "Jenkins"
                        git add k8s/frontend-deployment.yaml
                        git commit -m "ci: update frontend image to ${IMAGE_TAG}"
                        git push https://${GIT_USER}:${GIT_TOKEN}@github.com/dejourford/devops-code-challenge-3.git main
                    """
                }
            }
        }
    }
}