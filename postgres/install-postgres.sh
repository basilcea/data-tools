echo "Registering bitnami charts repository..."
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


echo "creating secrets"
kubectl apply -f secrets.env.yaml -n bi

echo "creating tls secrets"

kubectl create secret tls postgres-tls-secret --cert=tls.crt --key=tls.key -n bi
echo "Installing bitnami postgres..."
helm upgrade \
    --install \
    --values postgres-values.env.yaml \
    --namespace bi \
    database bitnami/postgresql