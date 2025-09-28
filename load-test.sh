#!/bin/bash

URL=$(minikube service web-service --url)
echo "Testing URL: $URL"

for i in {1..20}; do
  echo "Request $i"
  curl -s $URL | grep "visited"
  sleep 1
done
