resource "random_password" "restic_pvc_repo_password" {
  length = 24
}

resource "system_packages_apt" "deps" {
  for_each = toset(["sanoid", "restic"])

  package {
    name = each.value
  }
}

resource "system_folder" "etc_sanoid" {
  path  = "/etc/sanoid"
  user  = "root"
  group = "root"
}

resource "system_file" "sanoid_config" {
  path   = "/etc/sanoid/sanoid.conf"
  user   = "root"
  group  = "root"
  source = "../../secrets/backups/sanoid.conf"
}

resource "system_file" "sanoid_pre_snapshot_sh" {
  path   = "/etc/sanoid/pre-snapshot.sh"
  mode   = 755
  user   = "root"
  group  = "root"
  source = "../../secrets/backups/pre-snapshot.sh"
}

data "kubernetes_resources" "pvs" {
  api_version = "v1"
  kind        = "PersistentVolume"
}

data "healthchecksio_channel" "pushover" {
  kind = "po"
}

resource "healthchecksio_check" "pv_backup_checks" {
  for_each = {
    for pv in data.kubernetes_resources.pvs.objects : substr(pv.spec.claimRef.name, 0, 26) => pv.metadata.name
    if pv.spec.storageClassName == var.data_volume_storage_class
  }

  name = "PV Backup (${each.key})"
  desc = "Backup for PersistentVolume ${each.key} (${each.value})"

  grace   = 1800
  timeout = 3600

  channels = [data.healthchecksio_channel.pushover.id]
}

resource "system_file" "sanoid_post_snapshot_sh" {
  path  = "/etc/sanoid/post-snapshot.sh"
  user  = "root"
  group = "root"
  mode  = 755
  content = templatefile("../../secrets/backups/post-snapshot.sh", {
    access_key  = aws_iam_access_key.restic_access_keys.id,
    secret_key  = aws_iam_access_key.restic_access_keys.secret,
    bucket_name = data.aws_s3_bucket.backups.bucket,
    pvc_to_target_map = [
      for pv in data.kubernetes_resources.pvs.objects : {
        name   = pv.metadata.name,
        target = "${pv.spec.claimRef.namespace}--${pv.spec.claimRef.name}"
        hc_id  = healthchecksio_check.pv_backup_checks[substr(pv.spec.claimRef.name, 0, 26)].ping_url
      }
      if pv.spec.storageClassName == var.data_volume_storage_class
    ],

    restic_password = random_password.restic_pvc_repo_password.result
  })
}

output "backrest_config_json" {
  description = "JSON blob to copy into Backrest's config to have these PVC backups show up"
  sensitive   = true
  value = jsonencode([
    for pv in data.kubernetes_resources.pvs.objects : {
      id       = "${pv.spec.claimRef.namespace}--${pv.spec.claimRef.name}",
      uri      = "s3:s3.amazonaws.com/${data.aws_s3_bucket.backups.bucket}/${pv.spec.claimRef.namespace}--${pv.spec.claimRef.name}",
      password = random_password.restic_pvc_repo_password.result,
      env = [
        "AWS_ACCESS_KEY_ID=${aws_iam_access_key.restic_access_keys.id}",
        "AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.restic_access_keys.secret}"
      ],
      prunePolicy = {
        schedule = {
          maxFrequencyDays = 30
        },
        maxUnusedPercent = 25
      },
      checkPolicy = {
        schedule = {
          maxFrequencyDays = 30
        },
        readDataSubsetPercent = 10
      },
      autoUnlock    = true,
      commandPrefix = {}
  } if pv.spec.storageClassName == var.data_volume_storage_class])
}

resource "system_file" "sanoid_service" {
  path    = "/etc/systemd/system/sanoid.service"
  mode    = 644
  user    = "root"
  group   = "root"
  content = <<EOT
[Unit]
Description=Snapshot ZFS Pool
Requires=zfs.target
After=zfs.target
Wants=sanoid-prune.service
Before=sanoid-prune.service
ConditionFileNotEmpty=/etc/sanoid/sanoid.conf

[Service]
Environment=TZ=UTC
Type=oneshot
ExecStart=/usr/sbin/sanoid --take-snapshots --verbose
EOT
}

resource "system_file" "sanoid_prune_service" {
  path    = "/etc/systemd/system/sanoid-prune.service"
  mode    = 644
  user    = "root"
  group   = "root"
  content = <<EOT
[Unit]
Description=Cleanup ZFS Pool
Requires=zfs.target
After=zfs.target sanoid.service
ConditionFileNotEmpty=/etc/sanoid/sanoid.conf

[Service]
Environment=TZ=UTC
Type=oneshot
ExecStart=/usr/sbin/sanoid --prune-snapshots --verbose

[Install]
WantedBy=sanoid.service
EOT
}

resource "system_file" "sanoid_timer" {
  path    = "/etc/systemd/system/sanoid.timer"
  mode    = 644
  user    = "root"
  group   = "root"
  content = <<EOT
[Unit]
Description=Run Sanoid Every 20 Minutes
Requires=sanoid.service

[Timer]
OnCalendar=*:0/20
Persistent=true

[Install]
WantedBy=timers.target
EOT
}

resource "system_systemd_unit" "sanoid" {
  type    = "timer"
  name    = "sanoid"
  enabled = true
  status  = "started"
}
