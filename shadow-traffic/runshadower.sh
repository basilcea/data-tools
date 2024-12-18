kubectl get pods --no-headers  -n bi| grep '^shadowtraffic-shadower' | awk '{print $1}' | xargs kubectl delete pod -n bi
