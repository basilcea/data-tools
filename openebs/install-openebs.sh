# helm repo add openebs https://openebs.github.io/openebs
# helm repo update
# use mayastor replicated storage for on cloud kubernetes instance or data centers
# helm install openebs --namespace bi openebs/openebs -f openebs-values.yml
helm install openebs --namespace bi openebs/openebs --set engines.replicated.mayastor.enabled=false 