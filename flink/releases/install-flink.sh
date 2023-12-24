echo "Register airflow charts repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update


echo "Install flink"
helm upgrade \
    --install \
    --values flink-values.yml \
    --namespace bi \
    --timeout 10m \
    --debug \
    airflow apache-airflow/airflow