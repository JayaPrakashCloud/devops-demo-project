terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Install Prometheus and Grafana using Helm
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  set {
    name  = "prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues"
    value = "false"
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "postgres" {
  metadata {
    name = "postgres"
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          image = "postgres:15"
          name  = "postgres"

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_DB"
            value = "devops_demo"
          }

          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }

          volume_mount {
            mount_path = "/var/lib/postgresql/data"
            name       = "postgres-storage"
          }

          readiness_probe {
            exec {
              command = ["pg_isready", "-U", "postgres"]
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }

        volume {
          name = "postgres-storage"
          empty_dir {}
        }
      }
    }
  }
}

# PostgreSQL Service
resource "kubernetes_service" "postgres_service" {
  metadata {
    name = "postgres-service"
    labels = {
      app = "postgres"
    }
  }

  spec {
    selector = {
      app = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# Web Application Deployment
resource "kubernetes_deployment" "web" {
  metadata {
    name = "web"
    labels = {
      app = "web"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "web"
      }
    }

    template {
      metadata {
        labels = {
          app = "web"
        }
      }

      spec {
        container {
          image = var.web_image
          name  = "web"

          port {
            container_port = 5000
          }

          env {
            name  = "DB_HOST"
            value = "postgres-service"
          }

          env {
            name  = "DB_NAME"
            value = "devops_demo"
          }

          env {
            name  = "DB_USER"
            value = "postgres"
          }

          env {
            name  = "DB_PASSWORD"
            value = "password"
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 5000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
        }
      }
    }
  }
}

# Web Application Service
resource "kubernetes_service" "web_service" {
  metadata {
    name = "web-service"
    labels = {
      app = "web"
    }
  }

  spec {
    selector = {
      app = "web"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 5000
      node_port   = 30000
    }

    type = "NodePort"
  }
}
