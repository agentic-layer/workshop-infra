#!/bin/bash

# Script to generate shared kubeconfigs from workshop ServiceAccount tokens.
# Participants can use these kubeconfigs with just kubectl — no gcloud or Google account needed.

set -e

SA_NAMESPACE="workshop-system"
OUTPUT_DIR="kubeconfigs"

mkdir -p "$OUTPUT_DIR"

# Get the current cluster API server
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

generate_kubeconfig() {
  local secret_name="$1"
  local context_name="$2"
  local user_name="$3"
  local output_file="$4"

  local token ca
  token=$(kubectl get secret "$secret_name" -n "$SA_NAMESPACE" -o jsonpath='{.data.token}' | base64 -d)
  ca=$(kubectl get secret "$secret_name" -n "$SA_NAMESPACE" -o jsonpath='{.data.ca\.crt}')

  if [ -z "$token" ]; then
    echo "  ERROR: Token not found in secret $secret_name. Is the ServiceAccount deployed?"
    return 1
  fi

  cat > "$output_file" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: ${context_name}
    cluster:
      server: ${SERVER}
      certificate-authority-data: ${ca}
contexts:
  - name: ${context_name}
    context:
      cluster: ${context_name}
      user: ${user_name}
users:
  - name: ${user_name}
    user:
      token: ${token}
current-context: ${context_name}
EOF

  echo "  Generated: $output_file"
}

echo "================================================"
echo "Generating workshop kubeconfigs"
echo "================================================"
echo "API server: $SERVER"
echo ""

echo "Read-only kubeconfig (with write to ns-XX):"
generate_kubeconfig \
  "workshop-participant-token" \
  "workshop" \
  "workshop-participant" \
  "$OUTPUT_DIR/workshop-kubeconfig.yaml"

echo ""
echo "Admin kubeconfig (cluster-admin, backup):"
generate_kubeconfig \
  "workshop-participant-admin-token" \
  "workshop-admin" \
  "workshop-participant-admin" \
  "$OUTPUT_DIR/workshop-admin-kubeconfig.yaml"

echo ""
echo "================================================"
echo "To test:"
echo "  export KUBECONFIG=$OUTPUT_DIR/workshop-kubeconfig.yaml"
echo "  kubectl get namespaces"
echo ""
echo "Distribute workshop-kubeconfig.yaml to participants."
echo "Keep workshop-admin-kubeconfig.yaml as a backup."
