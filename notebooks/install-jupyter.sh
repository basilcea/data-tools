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

# helm repo update

helm upgrade --install my-notebooks bitnami/jupyterhub -f jupyter-values.env.yaml -n bi
