#!/bin/bash

URL=$(minikube service web-service --url)
echo "Generating traffic to: $URL"

while true; do
  curl -s $URL > /dev/null
  curl -s $URL/health > /dev/null
  curl -s $URL/visits > /dev/null
  echo "Sent requests..."
  sleep 2
done
