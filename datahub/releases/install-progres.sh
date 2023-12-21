echo "Registering bitnami charts repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami

echo "Installing bitnami postgres..."
helm upgrade \
    --install \
    --values postgres-values.yaml \
    --namespace bi \
    --version "11.9.1" \
    datahub-postgres bitnami/postgresql
