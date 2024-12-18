kubectl get deployments --no-headers  -n bi| grep '^my-cluster' | awk '{print $1}' | xargs kubectl delete deployment -n bi
kubectl get crds --no-headers  -n bi| grep 'strimzi' | awk '{print $1}' | xargs kubectl delete crd 
kubectl get pods --no-headers  -n bi| grep '^my-cluster' | awk '{print $1}' | xargs kubectl delete pod -n bi
kubectl get pvc --no-headers  -n bi| grep '\b\w*my-cluster\w*\b' | awk '{print $1}' | xargs kubectl delete pvc -n bi
helm list -n bi| grep '^my-cluster' | awk '{print $1}' | xargs helm uninstall -n bi