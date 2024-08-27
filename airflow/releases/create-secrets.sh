source .env
echo "Creating secret: airflow-user-secrets..."
kubectl delete  secret airflow-user-secrets 
kubectl create secret generic airflow-user-secrets \
--from-literal=connection=$CONNECTION \
--from-literal=webserver-secret-key=$(python3 -c "import secrets; print(secrets.token_hex(16))") \
--from-literal=fernet-key=$FERNET_KEY \
--from-literal=GITSYNC_USERNAME=$GIT_SYNC_USERNAME \
--from-literal=GITSYNC_PASSWORD=$GIT_SYNC_PASSWORD \
--from-literal=GIT_SYNC_USERNAME=$GIT_SYNC_USERNAME \
--from-literal=GIT_SYNC_PASSWORD=$GIT_SYNC_PASSWORD \
--from-literal=POSTGRES_USER=$POSTGRES_USER \
--from-literal=POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
--from-literal=POSTGRES_ADMIN_PASSWORD=$POSTGRES_ADMIN_PASSWORD \
--from-literal=AIRFLOW_CONN_AIRBYTE_HTTP_API=$AIRBYTE_HTTP_API \
--from-literal=AIRFLOW_CONN_AIRBYTE=$AIRBYTE_CONN_ID \
--from-literal=AIRFLOW_CONN_AIRBYTE_API=$AIRBYTE_API \
--from-literal=AIRFLOW_CONN_DATAHUB_REST_DEFAULT=$DATAHUB_HOST \
--from-literal=AIRFLOW_VAR_GITHUB_ACCESS_TOKEN=$GITHUB_ACCESS_TOKEN \
--from-literal=SODA_API_KEY=$SODA_API_KEY \
--from-literal=SODA_API_KEY_SECRET=$SODA_API_KEY_SECRET \
--from-literal=DBT_ENV_SECRET_SNOWFLAKE_PASSWORD=$DBT_ENV_SECRET_SNOWFLAKE_PASSWORD \
|| echo "Secret 'airflow-user-secrets' already exists"