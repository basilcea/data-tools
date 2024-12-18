# Deploying Kafka Using Strimzi
1. Create Namespace if not already existing
```kubectl create namespace <namespace>```
2. Run the following command to create strimzi kafka cluster operator
```helm install strimzi-cluster-operator oci://quay.io/strimzi-helm/strimzi-kafka-operator -n <namespace>```
3. Run the kafka-values.yml
```kubectl apply -f kafka-values.yaml -n <namespace>``
4. Run the kafka-connect-values.yml
```kubectl apply -f kafka-connect-values.yaml -n <namespace>``
5. Create push secret
``kubectl create secret docker-registry <secret-name> \
  --docker-username=<your-dockerhub-username> \
  --docker-password=<your-dockerhub-password> \
  --docker-email=<your-email>``
6.  Get Artifact for kafka connect

    You can get them from maven repositories or other open source repositories

7.  Create and run custom `KafkaConnectors` resource in kafka-connectors-values.yaml
```kubectl apply -f kafka-connectors-values.yaml -n <namespace>```
 - check if the custom connectors have been created
 ```kubectl get kctr --selector strimzi.io/cluster=<kafka-connect-cluster-name>```
  This process is used for kafka connectors cluster that has `strimzi.io/use-connector-resources: "true"`.

  The other cluster would use the rest api to set the values of the connect

8. Run Kubectl to confirm the data
```kubectl exec <my_kafka_cluster>-kafka-0 -i -t -- bin/kafka-console-consumer.sh --bootstrap-server <my_kafka_cluster>-kafka-bootstrap.NAMESPACE.svc:9092 --topic my-topic --from-beginning```



# Deploying Postgres with TLS

## Generating Self Signed TLS for Development Purposes

```openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -out request.csr
openssl x509 -req -days 365 -in request.csr -signkey tls.key -out tls.crt
rm request.csr
kubectl create secret tls my-tls-secret --cert=/path/to/cert.crt --key=/path/to/key.key
```

# Processing Yaml Files
The project include a process-yaml-files.sh command that fills up secrets from .env file into the respective places. This should only be used in development purposes.