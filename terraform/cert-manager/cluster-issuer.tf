resource "kubernetes_secret" "secret_access_key" {
  depends_on = [helm_release.cert_manager]

  metadata {
    name      = "prod-route53-credentials"
    namespace = var.namespace
  }

  data = {
    "secret-access-key" = aws_iam_access_key.cert_manager_access_keys.secret
  }
}

resource "kubernetes_manifest" "cluster_issuer" {
  depends_on = [
    helm_release.cert_manager,
    aws_iam_access_key.cert_manager_access_keys,
    kubernetes_secret.secret_access_key
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"

    metadata = {
      name = "letsencrypt"
    }

    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"

        privateKeySecretRef = {
          name = "letsencrypt-account-key"
        }

        solvers = [
          {
            dns01 = {
              route53 = {
                region       = "us-east-1"
                accessKeyID  = aws_iam_access_key.cert_manager_access_keys.id
                hostedZoneID = data.aws_route53_zone.services_domain.zone_id

                secretAccessKeySecretRef = {
                  name = "prod-route53-credentials"
                  key  = "secret-access-key"
                }
              }
            }
          }
        ]
      }
    }
  }
}
