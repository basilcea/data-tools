# Superset

This repo will install [Apache Superset](https://superset.apache.org/), an open-source BI solution.

It uses the official chart, but customized with some OAF values (such as installing the Elastic driver and the selenium webdriver).

## Installation

### Cluster setup

If you don't have a running k8s cluster you can spin one off in 2 commands by installing [minikube](https://minikube.sigs.k8s.io/docs/):

```sh
brew install minikube
minikube start
```

__NOTE__ on private registries: if using private images, you can use the `registry-creds` minikube addon to enable pulling from private registries:

```sh
# will prompt for credentials to the desired registries
minikube addons configure registry-creds
minikube addons enable registry-creds
```

### Install chart

```sh
# Install superset repository
helm repo add superset http://apache.github.io/superset/

# install the chart - feel free to override any value in test/my-values.yaml
helm upgrade --install \
  -f oaf-values.yaml \
  --set-file configOverrides.overrides=values/overrides.py \
  -f test/my-values.yaml \
  oaf-superset superset/superset
```
