#!/bin/bash

set -eu

if [ "$1" = "oaf-dev" ]; then
    echo "Deploying to OAF dev cluster..."
    export KUBECONFIG=$HOME/.kube/oaf-dev-config
    kubectl config use-context kubernetes-admin@kubernetes
elif [ "$1" = "minikube" ]; then
    echo "Deploying to local minikube instance..."
    kubectl config use-context minikube
    kubectl create namespace bi || echo "Failed to create namespace bi"
else
    echo "ERROR: Invalid or no deployment environment specified. Please use minikube or oaf-dev"
fi

# helm uninstall -n bi kafka
# kubectl delete -n bi pvc data-kafka-0 data-kafka-zookeeper-0

helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade \
  --install -n bi \
  --values kafka-values.yml \
  --version 22.1.6 \
  kafka bitnami/kafka 

