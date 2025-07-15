resource "kubernetes_config_map_v1" "nginx_config" {
  metadata {
    name      = "z2m-nginx-config"
    namespace = "default"
  }

  data = {
    "nginx.conf" = <<EOF
user  nginx;
worker_processes  1;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
  access_log  /var/log/nginx/access.log  main;
  sendfile        on;
  keepalive_timeout  65;
  server {
    listen 80;

    server_name ~^(?<subdomain>.*?)\.;

    location /healthz {
      return 200;
    }

    location / {
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "Upgrade";
      proxy_pass http://${var.z2m_host}:8080;
      proxy_set_header Host ${var.z2m_host};
      proxy_http_version 1.1;
    }
  }
}
EOF
  }
}

resource "kubernetes_deployment_v1" "z2m_nginx" {
  metadata {
    name      = "z2m-nginx"
    namespace = "default"
    labels = {
      app = "z2m"
    }
  }

  spec {
    selector {
      match_labels = {
        "app" = "z2m"
      }
    }

    replicas = 1

    template {
      metadata {
        labels = {
          app = "z2m"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:alpine@sha256:6e39bb3765ac959c7e1240509636173417a5e37abf140f418401e2fa73970bbe"

          port {
            container_port = 80
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/nginx.conf"
            sub_path   = "nginx.conf"
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map_v1.nginx_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "z2m_nginx" {
  metadata {
    name      = "z2m"
    namespace = "default"
  }

  spec {
    selector = {
      app = "z2m"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "nginx"
    }
  }
}

resource "kubernetes_ingress_v1" "healthchecks_io" {
  metadata {
    name      = "z2m"
    namespace = "default"

    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = var.z2m_url

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "z2m"

              port {
                name = "nginx"
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.z2m_url]
      secret_name = "z2m-ingress-cert"
    }
  }
}
