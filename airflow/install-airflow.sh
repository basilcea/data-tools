#!/bin/bash

# Parse command-line arguments\
set -a
source releases/.env
set +a
envsubst < releases/airflow-values.yml > releases/airflow-values-gen.yml
echo "$ENABLE_POSTGRESQL"
# Convert ENABLE_POSTGRESQL to boolean
if [[ "$ENABLE_POSTGRESQL" == "true" || "$ENABLE_POSTGRESQL" == "True" ]]; then
    ENABLE_POSTGRESQL=true
else
    ENABLE_POSTGRESQL=false
fi


echo "Register airbyte charts repository..."
# helm delete --namespace bi airflow
helm repo add apache-airflow https://airflow.apache.org

helm repo update
kubectl apply -f releases/webconfigmap.yml

# helm rollback airflow  --namespace bi
helm uninstall  airflow
kubectl delete pvc airflow-logs
kubectl delete pvc airflow-postgresql

echo "Install airflow"
helm upgrade \
    --install \
    --values releases/airflow-values-gen.yml \
    --set postgresql.enabled=$ENABLE_POSTGRESQL \
    --timeout 10m \
    --debug \
    airflow apache-airflow/airflow