helm uninstall shadower

echo "creating shadow traffic secrets"
kubectl apply -f secrets.env.yaml -n bi

helm upgrade \
    --install \
    --values values.env.yaml \
    --namespace bi \
    shadower  .