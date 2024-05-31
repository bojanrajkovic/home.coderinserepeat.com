resource "system_packages_apt" "ipmitool" {
  package {
    name = "ipmitool"
  }
}

resource "system_file" "ipmitool_fix_fans_service" {
  path    = "/etc/systemd/system/fix-fans-ipmi.service"
  mode    = 644
  user    = "root"
  group   = "root"
  content = <<EOT
[Unit]
Description=Fix fan speeds via IPMI
After=basic.target

[Service]
Type=oneshot
ExecStart=/usr/bin/ipmitool raw 0x30 0x70 0x66 0x01 0x00 0x30
ExecStart=/usr/bin/ipmitool raw 0x30 0x70 0x66 0x01 0x01 0x30
EOT
}

resource "system_file" "ipmitool_fix_fans_timer" {
  path    = "/etc/systemd/system/fix-fans-ipmi.timer"
  mode    = 644
  user    = "root"
  group   = "root"
  content = <<EOT
[Unit]
Description=Trigger fan speed fix via IPMI
PartOf=${basename(system_file.ipmitool_fix_fans_service.path)}

[Timer]
OnCalendar=minutely

[Install]
WantedBy=timers.target
EOT
}

resource "system_systemd_unit" "ipmitool_fix_fans_timer" {
  depends_on = [system_file.ipmitool_fix_fans_timer]
  type       = "timer"
  name       = "fix-fans-ipmi"
  status     = "started"
  enabled    = true
}
