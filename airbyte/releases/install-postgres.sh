echo "Registering bitnami charts repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
# helm uninstall database --namespace bi
# kubectl delete pvc data-database-postgresql-0 --namespace bi
echo "Installing bitnami postgres..."
helm upgrade \
    --install \
    --values postgres-values.yaml \
    --namespace bi \
    database bitnami/postgresql