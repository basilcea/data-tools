echo "Register airflow charts repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update


echo "Install flink"
helm upgrade \
    --install \
    --values _one-acre-fund.airflow/releases/flink-values.yml \
    --namespace bi \
    --timeout 10m \
    --debug \
    flink oci://registry-1.docker.io/bitnamicharts/flink 