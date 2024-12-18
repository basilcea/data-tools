helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  -f nginx-values.env.yaml
  --namespace bi --create-namespace 