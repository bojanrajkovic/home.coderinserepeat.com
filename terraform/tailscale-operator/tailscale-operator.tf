data "http" "tailscale_operator_manifest" {
  url = "https://raw.githubusercontent.com/tailscale/tailscale/main/cmd/k8s-operator/deploy/manifests/operator.yaml"
}

locals {
  operator_manifests = {
    for manifest in provider::kubernetes::manifest_decode_multi(data.http.tailscale_operator_manifest.response_body)
    : "${manifest.kind}--${manifest.metadata.name}" => manifest
  }
}

# Create namespace
resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

# Create 1Password item for OAuth credentials
resource "kubernetes_manifest" "tailscale_oauth_credentials" {
  depends_on = [kubernetes_namespace_v1.tailscale]

  manifest = {
    apiVersion = "onepassword.com/v1"
    kind       = "OnePasswordItem"

    metadata = {
      name      = var.oauth_credentials_secret
      namespace = kubernetes_namespace_v1.tailscale.metadata[0].name
    }

    spec = {
      itemPath = var.oauth_credentials_1password_vault_item_id
    }
  }
}

# Apply CRDs and other resources from the manifest
resource "kubernetes_manifest" "tailscale_operator_resources" {
  for_each = {
    for idx, manifest in local.operator_manifests :
    "${manifest.kind}-${try(manifest.metadata.name, idx)}" => manifest
    if manifest != null && manifest.kind != "Namespace" && manifest.kind != "Secret"
  }

  manifest = each.value

  depends_on = [
    kubernetes_namespace_v1.tailscale,
    kubernetes_manifest.tailscale_oauth_credentials
  ]
}

# Create Connector for subnet router to advertise cluster networks
resource "kubernetes_manifest" "tailscale_subnet_router" {
  manifest = {
    apiVersion = "tailscale.com/v1alpha1"
    kind       = "Connector"

    metadata = {
      name = "k8s-subnet-router"
    }

    spec = {
      hostname = var.subnet_router_hostname

      subnetRouter = {
        advertiseRoutes = var.advertised_routes
      }

      tags = ["tag:k8s"]
    }
  }

  depends_on = [
    kubernetes_manifest.tailscale_operator_resources,
    kubernetes_manifest.tailscale_oauth_credentials
  ]
}
