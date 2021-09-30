#!/bin/bash

# Define variables  
red='\e[1;31m%s\e[0m\n'
green='\e[1;32m%s\e[0m\n'
blue='\e[1;34m%s\e[0m\n'

SUBSCRIPTION=c5807190-2d73-4214-a65b-2416635845b8
# SUBSCRIPTION=0a52391c-0d81-434e-90b4-d04f5c670e8a
RG_NAME="rg-AzCon-dev"
AKS_NAME="aks-azcon-dev"
# RG_NAME="rg-CloudConnect-Dev"
# AKS_NAME="aks-kubenet-iuadjhoi5cjca"
ACR_NAME=registrypib4896

## 1. Set the right subscription
printf "$blue"  "*** Setting the subsription to $SUBSCRIPTION***"
az account set --subscription "$SUBSCRIPTION"

printf "$blue" "Set kube context to new cluster"
az aks get-credentials -g $RG_NAME -n $AKS_NAME --overwrite-existing --admin

kubectl apply -f namespaces.yaml

kubectl apply -f sql-secret.yaml

# deploy ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Use Helm to deploy an NGINX ingress controller
helm install nginx-ingress ingress-nginx/ingress-nginx \
    --namespace ns-ingress \
    --set controller.replicaCount=2 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set controller.admissionWebhooks.patch.nodeSelector."beta\.kubernetes\.io/os"=linux


# Deploy POI component
kubectl apply -f poi.yaml

# Deploy trips component
kubectl apply -f trips.yaml

# Deploy userprofile component
kubectl apply -f userprofile.yaml

# Deploy user-java component
kubectl apply -f user-java.yaml

# Deploy tripviewer component
kubectl apply -f tripviewer.yaml

kubectl apply -f api-ingress.yaml

kubectl apply -f web-ingress.yaml

# Check deployment
# kubectl get pods -n api
# kubectl get pods -n web
# kubectl get service --all-namespaces
# kubectl describe services tripviewer -n web

# Interactive terminal in a pod
# --> kubectl exec --stdin --tty trip-deployment-fcc7d8475-zm2rf -n api -- /bin/sh
# then you can do stuff like 
# -->   ls \
#       ps aux
# etc
# The short options -i and -t are the same as the long options --stdin and --tty, so the below command is the same
# kubectl exec -ti trip-deployment-fcc7d8475-zm2rf -n api -- /bin/sh