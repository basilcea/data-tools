if [ "$(RESET_ADMIN_PASSWORD)" != "true" ]; then
    exit 0
fi

echo "Resetting admin password..."

if [ -z "$(ADMIN_PASSWORD)" ]; then
    echo "ADMIN_PASSWORD variable not set!"
    exit 1
fi

PODNAME=`kubectl get pods --namespace bi | grep superset-worker | tail -n 1 | cut -d ' ' -f 1 -s`

if [ -z "$PODNAME" ]; then
    echo "No superset-worker pod found running!!!"
    exit 1
fi

kubectl exec --namespace bi pod/$PODNAME -- superset fab reset-password --username admin --password "$(ADMIN_PASSWORD)" 