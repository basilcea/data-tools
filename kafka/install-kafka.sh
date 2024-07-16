helm repo update
echo "Registering strimzi charts repository..."
helm repo add strimzi https://strimzi.io/charts/
echo "Registering kafka-ui charts repository..."
helm repo add kafka-ui https://kafbat.github.io/helm-charts
echo "Registering schema-registry charts repository..."
helm repo add lsstsqre https://lsst-sqre.github.io/charts/

echo "Installing strimizi cluster operator..."
helm upgrade --install -n bi \
 strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator

echo "Creating Metrics rules"
kubectl apply -f metrics.env.yaml -n bi


echo "Creating Kafka Cluster"
kubectl apply -f kafka-values.env.yaml -n bi

echo "Creating Kafka Connect"
kubectl apply -f kafka-connect-values.env.yaml -n bi

echo "Creating kafka Connectors"
kubectl apply -f kafka-connectors-values.env.yaml -n bi

echo "Creating kafka Bridge"
kubectl apply -f kafka-bridge-values.env.yaml -n bi

echo "Creating kafka Mirror Maker"
kubectl apply -f kafka-mirror-maker2-values.env.yaml -n bi


echo "Installing schema registry"
helm upgrade --install -n bi --values schema-registry-values.env.yaml lsstsqre/strimzi-registry-operator

echo "Creating Schema Registry Connection"
kubectl apply -f schema-registry-deployment.env.yaml -n bi

echo "Installing kafka ui"
helm upgrade --install -n bi --values kafka-ui-values.env.yaml kafka-ui kafka-ui/kafka-ui

