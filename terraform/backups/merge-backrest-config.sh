#!/usr/bin/env bash

set -euo pipefail

# Step 1: Extract JSON array from Terraform/Tofu output
echo "Extracting repos from Terraform state..."
TOFU_REPOS=$(tofu output -json | jq -r '.backrest_config_json.value')

# Validate it's an array
if ! echo "$TOFU_REPOS" | jq -e 'type == "array"' > /dev/null; then
    echo "Error: Expected array from Terraform output" >&2
    exit 1
fi

# Step 2: Find the backrest pod and transfer the config file
echo "Finding backrest pod..."
POD_NAME=$(kubectl get pods -n backrest -l app.kubernetes.io/name=backrest -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "Error: No pod found with label app.kubernetes.io/name=backrest" >&2
    exit 1
fi

echo "Found pod: $POD_NAME"
echo "Transferring config from pod..."

# Create a temp file for the original config
ORIGINAL_CONFIG=$(mktemp)
trap "rm -f $ORIGINAL_CONFIG" EXIT

kubectl exec -n backrest "$POD_NAME" -c backrest -- cat /config/config.json > "$ORIGINAL_CONFIG"

# Step 3 & 4: Merge arrays and sort by id
echo "Merging and sorting repos..."
MERGED_CONFIG=$(jq --argjson new_repos "$TOFU_REPOS" \
    '.repos = (.repos + $new_repos | unique_by(.id) | sort_by(.id))' \
    "$ORIGINAL_CONFIG")

# Output the result
# echo "$MERGED_CONFIG"

# Write back to the pod
echo "$MERGED_CONFIG" | kubectl exec -n backrest -i "$POD_NAME" -c backrest -- tee /config/config.json > /dev/null
echo "Config updated in pod"

# Send SIGHUP to the main process to reload config
echo "Sending SIGHUP to backrest process..."
kubectl exec -n backrest "$POD_NAME" -c backrest -- sh -c 'kill -HUP $(pidof backrest)'
echo "SIGHUP sent"
