# Frontend Deployment
resource "kubernetes_deployment" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      app = "frontend"
    }
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
          image = "637423621036.dkr.ecr.eu-central-1.amazonaws.com/grdn-ecr:frontend-v0.1"
          name  = "frontend"

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Backend Deployment
resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend"
  }

  spec {
    replicas = 2

    strategy {
      type = "Recreate"
    }

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
          image = "637423621036.dkr.ecr.eu-central-1.amazonaws.com/grdn-ecr:backend-v0.7"
          name  = "backend"

          env_from {
            secret_ref {
              name = "db-credentials-secret"
            }
          }

          port {
            container_port = 3000
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "1Gi"
            }
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 15
          }

          security_context {
            run_as_non_root = true
            run_as_user     = 1000
          }
        }
      }
    }
  }
  timeouts {
    create = "10m"
    update = "10m"
  }
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "backend"
  }
  spec {
    selector = {
      app = "backend"
    }
    port {
      port        = 80
      target_port = 3000
    }
    type = "LoadBalancer"
  }
}

resource "aws_iam_role" "external_secrets" {
  name = "${var.cluster_name}-external-secrets"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(local.oidc_provider_url, "https://", "")}:sub": "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_secrets_manager" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.external_secrets.name
}

resource "kubernetes_manifest" "external_secret" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "db-credentials"
      namespace = "default"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secrets-manager"
        kind = "SecretStore"
      }
      target = {
        name = "db-credentials-secret"
      }
      data = [
        {
          secretKey = "username"
          remoteRef = {
            key      = "db-credentials"
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = "db-credentials"
            property = "password"
          }
        },
        {
          secretKey = "host"
          remoteRef = {
            key      = "db-credentials"
            property = "host"
          }
        },
        {
          secretKey = "port"
          remoteRef = {
            key      = "db-credentials"
            property = "port"
          }
        },
        {
          secretKey = "dbname"
          remoteRef = {
            key      = "db-credentials"
            property = "dbname"
          }
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.secret_store]
}

resource "kubernetes_manifest" "secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "SecretStore"
    metadata = {
      name      = "aws-secrets-manager"
      namespace = "default"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.region
          auth = {
            jwt = {
              serviceAccountRef = {
                name = "external-secrets"
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.external_secrets]
}