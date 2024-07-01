#!/usr/bin/env bash
BUKKIT="${bucket_name}"

export AWS_SECRET_ACCESS_KEY="${secret_key}"
export AWS_ACCESS_KEY_ID="${access_key}"
export AWS_REGION="us-east-1"
export RESTIC_PASSWORD="${restic_password}"
export XDG_CACHE_HOME="/etc/sanoid/"

declare -A PVC_NAME_TO_REPOSITORY_NAME_MAP
%{ for pvc in pvc_to_target_map ~}
PVC_NAME_TO_REPOSITORY_NAME_MAP["${pvc.name}"]="${pvc.target}"
%{ endfor ~}

declare -A PVC_NAME_TO_HEALTHCHECK_ID_MAP
%{ for pvc in pvc_to_target_map ~}
PVC_NAME_TO_HEALTHCHECK_ID_MAP["${pvc.name}"]="${pvc.hc_id}"
%{ endfor ~}

post_update () {
    curl \
      -fsS \
      --data-raw "$${2}" \
      -X POST \
      --retry 5 \
      -m 10 \
      --write-out "\n" \
      -o /dev/null \
      "$${1}"
}


datasets=($${SANOID_TARGETS//,/})
snaps=($${SANOID_SNAPNAMES//,/})
tempdir="$${TMPDIR:-/tmp}"

for dataset in "$${datasets[@]}"; do
  if [ "x$${dataset}" == "xtank/docker/kubernetes" ]; then
    continue
  fi

  for snapshot in "$${snaps[@]}"; do
    ds_with_snapshot="$${dataset}@$${snapshot}"
    ds_basename=$(basename "$${dataset}")
    target=$${PVC_NAME_TO_REPOSITORY_NAME_MAP["$${ds_basename}"]}
    hc_url=$${PVC_NAME_TO_HEALTHCHECK_ID_MAP["$${ds_basename}"]}
    repo="s3:s3.amazonaws.com/$${BUKKIT}/$${target}"
    mountdir="$${tempdir}/$${target}"

    sanoid_check=$(sanoid --monitor-snapshots 2>&1)
    post_update "$${hc_url}/$?" "Finished snapshot $${snapshot} of $${dataset}:"$'\n\n'"$${sanoid_check}"
    
    mkdir -p "$${mountdir}"
    zfs release restic "$${ds_with_snapshot}" || true
    zfs hold restic "$${ds_with_snapshot}"
    mount -t zfs "$${ds_with_snapshot}" "$${mountdir}"
    post_update "$${hc_url}/start" "Starting upload of snapshot $${ds_with_snapshot} to $${repo}"

    if ! restic -r "$${repo}" cat config >/dev/null 2>&1; then
        restic -r "$${repo}" init
    fi

    pushd "$${mountdir}" >/dev/null 2>&1
    restic_output=$(restic -r "$${repo}" --compression max backup .)
    restic_return=$?
    popd >/dev/null 2>&1

    post_update "$${hc_url}/$${restic_return}" "Finished upload of snapshot $${ds_with_snapshot} to $${repo}:"$'\n\n'"$${restic_output}"

    post_update "$${hc_url}/start" "Starting pruning of snapshot $${ds_with_snapshot} to $${repo}"

    restic_output=$(restic -r "$${repo}" \
        forget \
        --keep-hourly 48 \
        --keep-daily 7 \
        --keep-weekly 8 \
        --keep-monthly 6 \
        --keep-yearly 1 \
        --prune
    )

    post_update "$${hc_url}/$?" "Finished pruning of restic repo $${repo}:"$'\n\n'"$${restic_output}"

    umount "$${mountdir}"
    rmdir "$${mountdir}"
    zfs release restic "$${ds_with_snapshot}" || true
  done
done

unset AWS_SECRET_ACCESS_KEY
unset AWS_ACCESS_KEY_ID
unset AWS_REGION