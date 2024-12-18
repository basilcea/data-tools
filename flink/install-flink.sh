
export $(grep -v '^#' ../.env | xargs)
keytool -genkeypair \
  -alias flink.internal \
  -keystore internal.keystore \
  -dname "CN=flink.internal" \
  -storepass $FLINK_SSL_PASSWORD \
  -keyalg RSA \
  -keysize 4096 \
  -storetype PKCS12

keytool -genkeypair -alias flink.rest -keystore rest.keystore -dname "CN=myhost.company.org" -ext "SAN=dns:myhost.company.org,ip:10.0.2.15" -storepass $FLINK_SSL_PASSWORD -keyalg RSA -keysize 4096 -storetype PKCS12

keytool -exportcert -keystore rest.keystore -alias flink.rest -storepass $FLINK_SSL_PASSWORD -file flink.cer

keytool -importcert -keystore rest.truststore -alias flink.rest -storepass $FLINK_SSL_PASSWORD -file flink.cer -noprompt


kubectl create secret generic flink-tls-secret \
  --from-file=internal.keystore=internal.keystore \
  --from-file=rest.keystore=rest.keystore \
  --from-file=rest.truststore=rest.truststore \
  --namespace=bi

rm -rf internal.keystore
rm -rf rest.keystore
rm -rf rest.truststore
rm -rf flink.cer



# helm repo add flink-operator-repo https://downloads.apache.org/flink/flink-kubernetes-operator-1.20.0/ -n bi
helm upgrade --install flink-kubernetes-operator flink-operator-repo/flink-kubernetes-operator -f flink-values.env.yaml -n bi --set webhook.create=false 

kubectl apply -f flinkDeployment.env.yaml -n bi
kubectl apply -f flinkSessionJob.env.yaml -n bi
kubectl apply -f flink-ha.env.yaml -n bi

if kubectl get configmap pyfiles -n bi > /dev/null 2>&1; then
    echo "ConfigMap 'pyfiles' exists. Updating..."
    
    # Delete and recreate the ConfigMap
    kubectl delete configmap pyfiles -n bi
    kubectl create configmap pyfiles --from-file=pyfiles/ -n bi
else
    echo "ConfigMap 'pyfiles' does not exist. Creating..."
    
    # Create the ConfigMap
    kubectl create configmap pyfiles --from-file=pyfiles/ -n bi
fi
