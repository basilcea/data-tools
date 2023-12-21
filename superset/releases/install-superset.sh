# add the repo and install deps
helm repo add superset http://apache.github.io/superset/
helm repo add bitnami https://charts.bitnami.com/bitnami/
helm repo update

echo ==> Values file
cat my-values.yaml
cat client_secrets.json

#git checkout 2.0.0

helm list -n $(NAMESPACE)

echo ==> Installing
# Note the quotes and escaping to pass extraConfigs.'gsheets-key.json'
helm upgrade \
  --install superset \
  --values oaf-values.yaml \
  --values my-values.yaml \
  --set-file configOverrides.overrides=overrides.py \
  --set-file 'extraSecrets.gsheets-key\.json=$(Agent.TempDirectory)/gsheets-key.json' \
  --set-file 'extraSecrets.keycloak_client_secrets\.json=client_secrets.json' \
  -n $(NAMESPACE) \
  --wait --timeout 15m --debug \
  superset/superset
