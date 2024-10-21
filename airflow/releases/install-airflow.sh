#!/bin/bash

# Parse command-line arguments\
set -a
source ./.env
set +a
envsubst < releases/airflow-values.yml > releases/airflow-values-gen.yml

DOCKERFILE="custom_image/Dockerfile"
REQUIREMENTS_FILE="custom_image/requirements.txt"

# if git diff --quiet HEAD -- "$DOCKERFILE" "$REQUIREMENTS_FILE"; then
#     echo "No changes detected in $DOCKERFILE or $REQUIREMENTS_FILE. Skipping docker buildx."
# else
#     echo "Changes detected in $DOCKERFILE or $REQUIREMENTS_FILE. Running docker buildx."
    
    AIRFLOW_VERSION="2.10.0"
    IMAGE_TAG="${AIRFLOW_VERSION}_$(date +'%Y%m%d_%H%M%S')"

    echo "Generated Image Tag: ${IMAGE_TAG}"

    echo "building airflow docker-image"
    docker buildx build --platform linux/amd64 -t mrcea/airflow:${IMAGE_TAG} -f ${DOCKERFILE}  --push .

    yq e ".images.airflow.tag = \"$IMAGE_TAG\"" -i "releases/airflow-values-gen.yml"
    yq e ".images.airflow.tag = \"$IMAGE_TAG\"" -i "releases/airflow-values.yml"
    echo "Updated IMAGE_TAG to: $IMAGE_TAG"
# fi


echo "Creating secret: airflow-user-secrets..."
kubectl create secret generic airflow-user-secrets \
    --from-literal=connection="postgresql://$POSTGRES_USER :$POSTGRES_PASSWORD @$POSTGRES_HOST:$POSTGRES_PORT /$POSTGRES_DB  \
    --from-literal=webserver-secret-key=$(python3 -c 'import secrets; print(secrets.token_hex(16))') \
    --from-literal=fernet-key=$FERNET_KEY  \
    --from-literal=GIT_SYNC_USERNAME=$GIT_SYNC_USERNAME  \
    --from-literal=GIT_SYNC_PASSWORD=$GIT_SYNC_PASSWORD  \
    --from-literal=GITSYNC_USERNAME=$GIT_SYNC_USERNAME  \
    --from-literal=GITSYNC_PASSWORD=$GIT_SYNC_PASSWORD  \
    --from-literal=DBT_ENV_SECRET_SNOWFLAKE_PASSWORD=$DBT_ENV_SECRET_SNOWFLAKE_PASSWORD  \
    --from-literal=SODA_API_KEY=$SODA_API_KEY \
    --from-literal=SODA_API_KEY_SECRET=$SODA_API_KEY_SECRET  \
    --from-literal=AIRFLOW_VAR_GITHUB_ACCESS_TOKEN=$GIT_SYNC_PASSWORD \
    --from-literal=DBT_ENV_SECRET_POSTGRES_PASSWORD=$DBT_ENV_SECRET_POSTGRES_PASSWORD  \
    -n bi " \
    -o yaml --dry-run=client | kubectl apply -f -

echo "Register airbyte charts repository..."
# helm delete --namespace bi airflow
helm repo add apache-airflow https://airflow.apache.org

kubectl apply -f releases/webconfigmap.yml

# helm rollback airflow  --namespace bi
helm uninstall  airflow
# kubectl delete pvc airflow-logs
# kubectl delete pvc airflow-postgresql

echo "Install airflow"
helm upgrade \
    --install \
    --namespace bi \
    --values releases/airflow-values-gen.yml \
    --timeout 10m \
    --debug \
    airflow apache-airflow/airflow

rm -rf airflow-values-gen.yml