output "web_service_url" {
  description = "URL to access the web application"
  value       = "Run: minikube service web-service --url"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "Run: kubectl port-forward service/kube-prometheus-stack-grafana 3000:80 -n monitoring"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "Run: kubectl port-forward service/kube-prometheus-stack-prometheus 9090:9090 -n monitoring"
}
