echo "Registering datahub charts repository..."
helm repo add datahub https://helm.datahubproject.io

echo "Creating secret: datahub-secrets..."
kubectl create \
    --namespace bi \
    secret generic datahub-secrets \
    --from-literal=postgres-app-password=$(POSTGRES_APP_PASSWORD) \
|| echo "Secret 'datahub-secrets' already exists"

echo "Creating config-map: datahub-frontend-volumes"
kubectl create \
    --namespace bi configmap datahub-frontend-volumes \
    --from-file=user.props \
|| echo "ConfigMap 'datahub-frontend-volumes' already exists"

echo "Installing Datahub..."
helm upgrade \
    --install \
    --values datahub-values.yaml \
    --namespace bi \
    --version "$(DATAHUB_HELM_CHART_VERSION)" \
    --timeout 900s \
    datahub datahub/datahub