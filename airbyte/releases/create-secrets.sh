echo "Creating secret: airbyte-secrets..."
kubectl delete --namespace bi secret airbyte-secrets 
kubectl create \
--namespace bi \
    secret generic airbyte-secrets \
    --from-literal=POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
    --from-literal=MINIO_PASSWORD=$(MINIO_PASSWORD) \
    --from-literal=DATABASE_PASSWORD=$(POSTGRES_PASSWORD) \
    --from-literal=POSTGRES_PWD=$(POSTGRES_PASSWORD) \
    --from-literal=DATABASE_USER=$(POSTGRES_USER) \
    --from-literal=POSTGRES_ADMIN_PASSWORD=$(POSTGRES_ADMIN_PASSWORD) \
|| echo "Secret 'airbyte-secrets' already exists"