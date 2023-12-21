echo "Register airbyte charts repository..."
helm repo add airbyte https://airbytehq.github.io/helm-charts

helm repo update

# echo "Uninstalling Airbyte..."
# helm uninstall --namespace bi airbyte
# kubectl delete pvc airbyte-minio-pv-claim-airbyte-minio-0 --namespace bi

echo "Install airbyte"
helm upgrade \
    --install \
    --values airbyte_values.yaml \
    --namespace bi \
    --timeout 10m \
    --debug \
    --version $(HELM_CHART_VERSION) \
    airbyte airbyte/airbyte