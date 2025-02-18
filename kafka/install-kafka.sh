
echo "Registering strimzi charts repository..."
helm repo add strimzi https://strimzi.io/charts/
echo "Registering kafka-ui charts repository..."
helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts
echo "Registering schema-registry charts repository..."
helm repo add lsstsqre https://lsst-sqre.github.io/charts/
echo "Registering gogatekeeper charts repository..."
helm repo add gogatekeeper https://gogatekeeper.github.io/helm-gogatekeeper

echo "Creating Secrets"
kubectl apply -f secrets.env.yaml -n bi

echo "Installing strimizi cluster operator..."
helm upgrade --install -n bi \
 my-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator

echo "Creating Push Secret"


echo "Creating Kafka Cluster"
kubectl apply -f kafka-values.env.yaml -n bi


echo "Creating Kafka Connect"
kubectl apply -f kafka-connect-values.env.yaml -n bi

echo "Creating kafka Bridge"
kubectl apply -f kafka-bridge-values.env.yaml -n bi

echo "Creating kafka Mirror Maker"
kubectl apply -f kafka-mirror-maker2-values.env.yaml -n bi

echo "Creating kafka Connectors"
kubectl apply -f kafka-connectors-values.env.yaml -n bi

echo "Creating Scram User"
kubectl apply -f kafka-scram-user.env.yaml -n bi

echo "Installing schema registry"

helm upgrade --install -n bi --values schema-registry-values.env.yaml my-cluster-registry-operator lsstsqre/strimzi-registry-operator

echo "Creating Schema Registry Connection"
kubectl apply -f schema-registry-deployment.env.yaml -n bi

ENV_FILE=../.env

export $(grep -v '^#' "$ENV_FILE" | xargs)
kubectl get secret  keycloak-crt -n bi  -o jsonpath='{.data.ca\.crt}'  | base64 --decode > keycloak.crt
kubectl get secret  keycloak-crt -n bi -o jsonpath='{.data.tls\.crt}' | base64 --decode > tls.crt
kubectl get secret  keycloak-crt -n bi -o jsonpath='{.data.tls\.key}' | base64 --decode > tls.key
kubectl get secret  my-cluster-a-cluster-ca-cert -n bi -o jsonpath='{.data.ca\.crt}' | base64 --decode > cluster.crt
kubectl get secret  my-cluster-a-cluster-ca-cert -n bi -o jsonpath='{.data.ca\.p12}' | base64 --decode > cluster.p12
CLUSTERTRUSTSTORE_PASSWORD=$(kubectl get secret  my-cluster-a-cluster-ca-cert -n bi -o jsonpath='{.data.ca\.password}' | base64 --decode )
# Retrieve secrets from Kubernetes



# Ensure the file exists
if [[ ! -f $ENV_FILE ]]; then
    echo "$ENV_FILE does not exist. Creating it..."
    touch $ENV_FILE
fi

echo "$CLUSTERTRUSTSTORE_PASSWORD"
if grep -q "^CLUSTERTRUSTSTORE_PASSWORD=" "$ENV_FILE"; then
        # Key exists; update it
        echo "Key exists"
        escaped_password=$(printf '%s' "$CLUSTERTRUSTSTORE_PASSWORD" | sed 's/[&/\]/\\&/g')
        sed -i '' "s|^CLUSTERTRUSTSTORE_PASSWORD=.*|CLUSTERTRUSTSTORE_PASSWORD=$escaped_password|" "$ENV_FILE"
    else
        # Key doesn't exist; append it
        echo "Key deos not exists"
        echo "CLUSTERTRUSTSTORE_PASSWORD=$CLUSTERTRUSTSTORE_PASSWORD" >> "$ENV_FILE"
    fi


openssl pkcs12 -export \
    -in tls.crt \
    -certfile keycloak.crt \
    -inkey tls.key \
    -out keycloakstore.p12 \
    -name keycloak \
    -passout pass:$KEYCLOAKSTORE_PASSWORD 


keytool -importkeystore -srckeystore keycloakstore.p12 \
 -srcstorepass $KEYCLOAKSTORE_PASSWORD\
 -srcstoretype PKCS12 -destkeystore keycloakstore.jks -deststoretype JKS \
 -alias keycloak \
 -deststorepass $KEYCLOAKSTORE_PASSWORD

keytool -importcert \
    -trustcacerts \
    -file keycloak.crt \
    -keystore keycloaktruststore.jks \
    -storetype JKS \
    -alias keycloak-trust \
    -storepass $KEYCLOAKTRUSTSTORE_PASSWORD \
    -noprompt

keytool -importkeystore -srckeystore cluster.p12 \
 -srcstorepass $CLUSTERTRUSTSTORE_PASSWORD \
 -srcstoretype PKCS12 -destkeystore clusterstore.jks -deststoretype JKS \
 -alias ca.crt \
 -deststorepass $CLUSTERTRUSTSTORE_PASSWORD

keytool -importcert \
    -trustcacerts \
    -file cluster.crt \
    -keystore clustertruststore.jks \
    -storetype JKS \
    -alias ca-trust \
    -storepass $CLUSTERTRUSTSTORE_PASSWORD \
    -noprompt



kubectl create secret generic store -n bi \
    --from-file=keycloakstore.jks=keycloakstore.jks \
    --from-literal=keycloakstore_password=$KEYCLOAKSTORE_PASSWORD \
    --from-file=keycloaktruststore.jks=keycloaktruststore.jks \
    --from-literal=keycloaktruststore_password=$KEYCLOAKTRUSTSTORE_PASSWORD \
    --from-file=clusterstore.jks=clusterstore.jks \
    --from-literal=clusterstore_password=$CLUSTERTRUSTSTORE_PASSWORD  \
    --from-file=clustertruststore.jks=clustertruststore.jks \
    --from-file=clustertruststore.p12=cluster.p12 \
    --from-literal=clustertruststore_password=$CLUSTERTRUSTSTORE_PASSWORD \
    --dry-run=client -o yaml | kubectl apply -f -


rm -f keycloakstore.jks
rm -f keycloakstore.p12
rm -f keycloaktruststore.jks
rm -f tls.crt
rm -f tls.key
rm -f keycloak.crt
rm -f cluster.crt
rm -f cluster.p12
rm -f clusterstore.jks
rm -f clustertruststore.jks

# echo "Installing ui gatekeeper"
# helm upgrade --install -n bi --values gatekeeper-values.env.yaml my-cluster-gogatekeeper gogatekeeper/gatekeeper

echo "Installing kafka ui"
helm upgrade --install -n bi --values kafka-ui-values.env.yaml my-cluster-kafka-ui kafka-ui/kafka-ui


# echo "Creating Metrics rules"
# kubectl apply -f metrics.env.yaml -n bi

# strimzi drain cleaner

# strimzi metrics and distributed tracing
# echo adding cruise control and rebalance

# securing kafka bridge using nginx so it calls a https endpiont instead of bridge internal http endpoint and nginx can then redirect it to the http endpoint

# cruise control ui



