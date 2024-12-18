echo "Registering bitnami charts repository..."

echo "127.0.0.1 keycloak" | sudo tee -a /etc/hosts
helm repo add bitnami https://charts.bitnami.com/bitnami
# helm uninstall database --namespace bi
# kubectl delete pvc data-database-postgresql-0 --namespace bi
NAMESPACE=bi

if kubectl get namespace $NAMESPACE; then
  echo "Namespace $NAMESPACE already exists."
else
  echo "Namespace $NAMESPACE does not exist. Creating it..."
  kubectl create namespace $NAMESPACE
fi
helm uninstall eventing



echo "creating rabbitmq secrets"
kubectl apply -f secrets.env.yaml -n bi

echo "Installing rabbitmq..."
helm upgrade \
    --install \
    --values rabbitmq-values.env.yaml \
    --namespace bi \
    eventing bitnami/rabbitmq