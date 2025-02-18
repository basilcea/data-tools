# Write your commands here
# i had to go sudo nano etc/host and add the ingress external ip which happens to be localhost to the list of host and set cea.local to 127.0.0.1 and localhost
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
