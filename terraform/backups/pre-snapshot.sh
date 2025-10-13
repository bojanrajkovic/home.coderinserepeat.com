#!/usr/bin/env bash
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

for dataset in "$${datasets[@]}"; do
  if [ "x$${dataset}" == "xtank/docker/kubernetes" ]; then
    continue
  fi

  for snapshot in "$${snaps[@]}"; do
    ds_basename=$(basename "$${dataset}")
    hc_url=$${PVC_NAME_TO_HEALTHCHECK_ID_MAP["$${ds_basename}"]}

    post_update "$${hc_url}/start" "Starting snapshot $${snapshot} of dataset $${dataset}"
  done
done
