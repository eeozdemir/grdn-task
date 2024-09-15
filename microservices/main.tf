provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          image = var.frontend_image
          name  = "frontend"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend"
  }

  spec {
    selector = {
      app = kubernetes_deployment.frontend.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          image = var.backend_image
          name  = "backend"

          port {
            container_port = 3000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"
  }

  spec {
    selector = {
      app = kubernetes_deployment.backend.metadata[0].labels.app
    }

    port {
      port        = 3000
      target_port = 3000
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "my_app_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "Ingress"
    metadata = {
      name = "my-app-ingress"
      annotations = {
        "kubernetes.io/ingress.class"           = "alb"
        "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
        "alb.ingress.kubernetes.io/target-type" = "ip"
      }
    }
    spec = {
      rules = [{
        http = {
          paths = [
            {
              path     = "/api"
              pathType = "Prefix"
              backend = {
                service = {
                  name = kubernetes_service.backend.metadata[0].name
                  port = {
                    number = 3000
                  }
                }
              }
            },
            {
              path     = "/"
              pathType = "Prefix"
              backend = {
                service = {
                  name = kubernetes_service.frontend.metadata[0].name
                  port = {
                    number = 80
                  }
                }
              }
            }
          ]
        }
      }]
    }
  }
}