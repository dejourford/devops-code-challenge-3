#!/bin/bash
set -e

CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name)
REGION="us-east-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
PRINCIPAL_ARN=$(aws sts get-caller-identity --query Arn --output text)
LB_ROLE_ARN=$(cd terraform && terraform output -raw lb_controller_role_arn)
VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION --query "cluster.resourcesVpcConfig.vpcId" --output text)
FRONTEND_REPO=$(cd terraform && terraform output -raw frontend_repo_url)
BACKEND_REPO=$(cd terraform && terraform output -raw backend_repo_url)

echo "=== Configuring kubectl ==="
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

echo "=== Creating EKS access entry ==="
aws eks create-access-entry \
  --cluster-name $CLUSTER_NAME \
  --principal-arn $PRINCIPAL_ARN \
  --region $REGION 2>/dev/null || echo "Access entry already exists"

aws eks associate-access-policy \
  --cluster-name $CLUSTER_NAME \
  --principal-arn $PRINCIPAL_ARN \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region $REGION 2>/dev/null || echo "Access policy already associated"

echo "=== Waiting for access entry to propagate ==="
sleep 15

echo "=== Installing AWS Load Balancer Controller ==="
helm repo add eks https://aws.github.io/eks-charts 2>/dev/null || true
helm repo update

kubectl create serviceaccount aws-load-balancer-controller \
  -n kube-system 2>/dev/null || echo "Service account already exists"

kubectl annotate serviceaccount aws-load-balancer-controller \
  -n kube-system \
  eks.amazonaws.com/role-arn=$LB_ROLE_ARN \
  --overwrite

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=$REGION \
  --set vpcId=$VPC_ID

echo "=== Installing Metrics Server ==="
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl patch deployment metrics-server -n kube-system \
  --type='json' \