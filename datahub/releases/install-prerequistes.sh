echo "Registering datahub charts repository..."
helm repo add datahub https://helm.datahubproject.io

# NOTE: Patching of any parameters in the elastic statefulset results
# in an error to do with some of the overrides of hardcoded environment
# variables that we have. Work around is to just recreate the statefulset.
kubectl delete -n bi statefulset/elasticsearch-master

echo "Installing Kafka & elasticsearch..."
helm upgrade \
    --install \
    --values prerequisites-values.yaml \
    --set elasticsearch.maxUnavailable=0 \
    --debug \
    --version "$(DATAHUB_PREREQUISITES_CHART_VERSION)" \
    --namespace bi \
    datahub-prerequisites datahub/datahub-prerequisites