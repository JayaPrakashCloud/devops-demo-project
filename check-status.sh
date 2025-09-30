#!/bin/bash

echo "=========================="
echo "DevOps Demo Status Check"
echo "=========================="
echo

echo "1. Minikube Status:"
minikube status
echo

echo "2. Kubernetes Nodes:"
kubectl get nodes
echo

echo "3. Application Pods:"
kubectl get pods -l app=web
echo

echo "4. Database Pods:"
kubectl get pods -l app=postgres
echo

echo "5. Services:"
kubectl get services
echo

echo "6. Monitoring Pods:"
kubectl get pods -n monitoring | grep -E "(prometheus|grafana)"
echo

echo "7. Application URL:"
APP_URL=$(minikube service web-service --url)
echo $APP_URL
echo

echo "8. Testing Application:"
curl -s $APP_URL | grep -o "visited.*times" || echo "Could not get visit count"
echo

echo "9. Health Check:"
curl -s $APP_URL/health | python3 -m json.tool 2>/dev/null || echo "Health check failed"
echo

echo "10. GitLab Pipeline Status:"
echo "Check: https://gitlab.com/YOUR_GITLAB_USERNAME/devops-demo-project/-/pipelines"
echo

echo "11. Grafana Access:"
echo "Run: kubectl port-forward service/kube-prometheus-stack-grafana 3000:80 -n monitoring"
echo "Then visit: http://localhost:3000 (admin/admin123)"
echo

echo "Status check completed!"
