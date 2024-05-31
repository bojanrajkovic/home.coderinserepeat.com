resource "system_packages_apt" "samba" {
  for_each = toset(["samba", "smbclient", "samba-vfs-modules"])
  package {
    name = each.value
  }
}

resource "system_file" "smb_conf" {
  path   = "/etc/samba/smb.conf"
  mode   = 644
  user   = "root"
  group  = "root"
  source = "../../secrets/samba/smb.conf"
}

resource "system_service_systemd" "samba" {
  depends_on = [system_file.smb_conf]
  name       = "smbd"
  status     = "started"
  enabled    = true
}
