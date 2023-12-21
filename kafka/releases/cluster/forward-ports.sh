#!/bin/bash

set -e

kubectl port-forward -n bi svc/rabbitmq 5672:5672 1> /dev/null &
kubectl port-forward -n bi svc/kafka 9092:9092 1> /dev/null &
kubectl port-forward -n bi $(kubectl get -n bi pods | grep kafka-kouncil | cut -f 1 -d ' ') 8080:8080 1> /dev/null &

cat <<-EOF
Forwarding services:
 - Rabbitmq (:5672)
 - Kafka (:9092)
 - Kouncil (http://localhost:8080)
EOF

wait
