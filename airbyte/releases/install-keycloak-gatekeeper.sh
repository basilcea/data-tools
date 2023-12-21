# Write your commands here
set -o xtrace

helm repo add gogatekeeper https://gogatekeeper.github.io/helm-gogatekeeper

helm upgrade --install $(KEYCLOAK_GATEKEEPER_NAME) \
  --values gatekeeper-values.yaml \
  --namespace $(NAMESPACE) \
  --debug --timeout 5m \
gogatekeeper/gatekeeper
