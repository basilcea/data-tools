echo "Creating secret: airflow-user-secrets..."
kubectl delete --namespace bi secret airflow-user-secrets 
kubectl create \
--namespace bi \
secret generic airflow-user-secrets \
--from-literal=connection=$(CONNECTION) \
--from-literal=webserver-secret-key=$(python3 -c 'import secrets; print(secrets.token_hex(16))') \
--from-literal=fernet-key=$(FERNET_KEY) \
--from-literal=GIT_SYNC_USERNAME=$(GIT_SYNC_USERNAME) \
--from-literal=GIT_SYNC_PASSWORD=$(GIT_SYNC_PASSWORD) \
--from-literal=POSTGRES_USER=$(POSTGRES_USER) \
--from-literal=POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) \
--from-literal=POSTGRES_ADMIN_PASSWORD=$(POSTGRES_ADMIN_PASSWORD) \
|| echo "Secret 'airflow-user-secrets' already exists"