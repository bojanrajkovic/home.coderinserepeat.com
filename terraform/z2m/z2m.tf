resource "kubernetes_namespace_v1" "z2m" {
  metadata {
    name = var.namespace_name

    labels = {
      "operator.1password.io/auto-restart" = true
    }
  }
}

resource "helm_release" "z2m" {
  depends_on = [kubernetes_namespace_v1.z2m]

  repository = "https://charts.zigbee2mqtt.io"
  chart      = "zigbee2mqtt"
  name       = "z2m"
  namespace  = var.namespace_name
  version    = "2.6.2"

  # Storage configuration
  set {
    name  = "statefulset.storage.enabled"
    value = "true"
  }

  set {
    name  = "statefulset.storage.size"
    value = var.storage_size
  }

  set {
    name  = "statefulset.storage.storageClassName"
    value = var.storage_class
  }

  # Serial port configuration (network-based adapter)
  set {
    name  = "zigbee2mqtt.serial.port"
    value = var.serial_port
  }

  set {
    name  = "zigbee2mqtt.serial.baudrate"
    value = "115200"
  }

  set {
    name  = "zigbee2mqtt.serial.adapter"
    value = "ember"
  }

  set {
    name  = "zigbee2mqtt.serial.disable_led"
    value = "false"
  }

  # MQTT configuration
  set {
    name  = "zigbee2mqtt.mqtt.server"
    value = var.mqtt_server
  }

  set {
    name  = "zigbee2mqtt.mqtt.base_topic"
    value = "z2m-new"
  }

  set {
    name  = "zigbee2mqtt.mqtt.user"
    value = var.mqtt_username
  }

  set {
    name  = "zigbee2mqtt.mqtt.password"
    value = var.mqtt_password
  }

  # General configuration
  set {
    name  = "zigbee2mqtt.advanced.log_level"
    value = var.log_level
  }

  set {
    name  = "zigbee2mqtt.advanced.transmit_power"
    value = "20"
  }

  set {
    name  = "zigbee2mqtt.permit_join"
    value = var.permit_join
  }

  set {
    name  = "env.TZ"
    value = "America/New_York"
  }

  # Home Assistant integration
  set {
    name  = "zigbee2mqtt.homeassistant.enabled"
    value = "true"
  }

  # Frontend configuration
  set {
    name  = "zigbee2mqtt.frontend.port"
    value = "8080"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.ingressClassName"
    value = "traefik"
  }

  set {
    name  = "ingress.annotations[0]"
    value = "cert-manager.io/cluster-issuer=letsencrypt"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = var.z2m_host
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/"
  }

  set {
    name  = "ingress.hosts[0].paths[0].pathType"
    value = "ImplementationSpecific"
  }

  set {
    name  = "ingress.hosts[0].paths[1].path"
    value = "/api"
  }

  set {
    name  = "ingress.hosts[0].paths[1].pathType"
    value = "ImplementationSpecific"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = var.z2m_host
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "z2m-ingress-cert"
  }
}
