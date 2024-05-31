resource "grafana_contact_point" "pushover" {
  name = "Pushover"

  pushover {
    api_token   = var.pushover_api_token
    user_key    = var.pushover_user_key
    ok_sound    = "Magic"
    sound       = "Default"
    priority    = 2
    ok_priority = 2
  }
}

resource "grafana_notification_policy" "default" {
  contact_point = grafana_contact_point.pushover.name
  group_by      = ["grafana_folder", "alertname"]
}

import {
  to = grafana_contact_point.pushover
  id = "Pushover"
}

import {
  to = grafana_notification_policy.default
  id = "Default policy"
}
