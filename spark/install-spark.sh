echo "Registering bitnami charts repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
# helm uninstall database --namespace bi
# kubectl delete pvc data-database-postgresql-0 --namespace bi
SPARK_MASTER_POD="spark-master-0"
NAMESPACE=bi

if kubectl get namespace $NAMESPACE; then
  echo "Namespace $NAMESPACE already exists."
else
  echo "Namespace $NAMESPACE does not exist. Creating it..."
  kubectl create namespace $NAMESPACE
fi

echo "applying secrets"
kubectl apply -f secrets.env.yaml -n bi

echo "updating spark config and volumes"

kubectl apply -f spark-config.env.yaml -n bi
kubectl apply -f spark-pv.env.yml -n bi


echo "Installing Spark"

helm upgrade -install spark bitnami/spark -f spark-values.env.yaml -n bi

is_pod_and_container_ready() {
  POD_STATUS=$(kubectl get pod $SPARK_MASTER_POD -n $NAMESPACE -o jsonpath='{.status.phase}')
  CONTAINER_READY=$(kubectl get pod $SPARK_MASTER_POD -n $NAMESPACE -o jsonpath='{.status.containerStatuses[0].ready}')
  
  if [ "$POD_STATUS" == "Running" ] && [ "$CONTAINER_READY" == "true" ]; then
    return 0  # Pod is running and the container is ready
  else
    return 1  # Pod or container is not ready
  fi
}

# Wait until the Spark master pod is running and the container is ready
echo "Waiting for $SPARK_MASTER_POD to be in the 'Running' state and container to be 'Ready'..."
while ! is_pod_and_container_ready; do
  echo "Pod or container is not yet ready. Retrying in 5 seconds..."
  sleep 5
done

echo "$SPARK_MASTER_POD is running and the container is ready!"

# Port forward to access Spark UI
kubectl port-forward svc/spark-master-svc 8015:443 -n bi



