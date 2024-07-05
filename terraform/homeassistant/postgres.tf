resource "kubernetes_namespace_v1" "home_assistant" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "kubernetes_manifest" "recorder_certificate" {
  depends_on = [kubernetes_namespace_v1.home_assistant]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"

    metadata = {
      name      = "recorder-certificate"
      namespace = kubernetes_namespace_v1.home_assistant.metadata[0].name
    }

    spec = {
      secretName = var.postgres_cert_secret_name
      usages     = ["server auth"]
      dnsNames   = [var.postgres_hostname]

      issuerRef = {
        name  = "letsencrypt"
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
    }
  }
}

resource "kubernetes_secret" "recorder_ca_certificate" {
  data = {
    "ca.crt" = file("./lets-encrypt-x1-root.crt")
  }

  metadata {
    name      = "lets-encrypt-x1-root"
    namespace = kubernetes_namespace_v1.home_assistant.metadata[0].name
  }
}

resource "kubernetes_manifest" "recorder_cluster" {
  depends_on = [
    kubernetes_namespace_v1.home_assistant,
    kubernetes_manifest.recorder_certificate
  ]

  manifest = {
    apiVersion = "postgresql.cnpg.io/v1"
    kind       = "Cluster"

    metadata = {
      name      = "recorder-cluster"
      namespace = kubernetes_namespace_v1.home_assistant.metadata[0].name
    }

    spec = {
      instances = 1

      certificates = {
        serverTLSSecret = var.postgres_cert_secret_name
        serverCASecret  = kubernetes_secret.recorder_ca_certificate.metadata[0].name
      }

      storage = {
        size         = "50Gi"
        storageClass = "zfs-durable"
      }

      bootstrap = {
        initdb = {
          database = "recorder"
          owner    = "homeassistant"
        }
      }
    }
  }
}

resource "kubernetes_manifest" "recorder_cluster_monitor" {
  depends_on = [kubernetes_manifest.recorder_cluster]

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PodMonitor"

    metadata = {
      name      = "recorder-cluster-monitor"
      namespace = kubernetes_namespace_v1.home_assistant.metadata[0].name

      labels = {
        "release" = "kube-prometheus"
      }
    }

    spec = {
      selector = {
        matchLabels = {
          "cnpg.io/cluster" = kubernetes_manifest.recorder_cluster.manifest.metadata.name
        }
      }

      podMetricsEndpoints = [{ port = "metrics" }]
    }
  }
}

resource "kubernetes_service_v1" "postgres_service" {
  metadata {
    name      = "recorder-service"
    namespace = kubernetes_namespace_v1.home_assistant.metadata[0].name

    annotations = {
      "external-dns.alpha.kubernetes.io/hostname"  = var.postgres_hostname
      "metallb.universe.tf/ip-allocated-from-pool" = "metallb-address-pool"
    }
  }

  spec {
    type = "LoadBalancer"

    port {
      name        = "postgres"
      port        = 5432
      protocol    = "TCP"
      target_port = 5432
    }

    selector = {
      "cnpg.io/cluster" = "recorder-cluster"
      "role"            = "primary"
    }
  }
}
