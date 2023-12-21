echo "Register airbyte charts repository..."
helm repo add apache-airflow https://airflow.apache.org

helm repo update
kubectl apply -f _one-acre-fund_airflow/webconfigmap.yml

# helm rollback airflow  --namespace bi
# helm uninstall --namespace bi airflow
# kubectl delete pvc data-airflow-postgresql-0 --namespace bi

echo "Install airflow"
helm upgrade \
    --install \
    --values airflow-values.yml \
    --namespace bi \
    --timeout 10m \
    --debug \
    airflow apache-airflow/airflow