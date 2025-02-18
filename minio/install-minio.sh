echo "Creating Secrets"
kubectl apply -f secrets.env.yaml -n bi

echo "Creating Storage Class"
kubectl apply -f minio-storage-class.yaml -n bi

echo 'Creating Minio Operator'

# helm repo add minio-operator https://operator.min.io

# # openssl x509 -in ca.crt -text -noout

# # # openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
# # #   -keyout private.key -out public.crt -config ssl.conf



# helm uninstall minio-operator -n bi
helm upgrade --install \
  --namespace bi\
  minio-operator minio-operator/operator


helm uninstall minio-tenant -n bi

echo 'Creating Minio Tenants'
helm upgrade --install \
--namespace bi \
--values minio-tenant-values.yaml \
minio-tenant minio-operator/tenant

