# Write your commands here
set -o xtrace

helm repo add gogatekeeper https://gogatekeeper.github.io/helm-gogatekeeper

echo "creating secrets"
kubectl apply -f secrets.env.yaml -n bi

helm upgrade --install keycloak \
  --values keycloak-values.env.yaml \
  --namespace bi \
  --debug --timeout 5m \
  bitnami/keycloak
# gogatekeeper/gatekeeper
