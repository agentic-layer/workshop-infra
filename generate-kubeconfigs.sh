#!/bin/bash

# Script to generate a shared kubeconfig from the workshop-participant ServiceAccount token.
# Participants can use this kubeconfig with just kubectl — no gcloud or Google account needed.

set -e

SA_NAMESPACE="workshop-system"
SECRET_NAME="workshop-participant-token"
OUTPUT_DIR="kubeconfigs"
OUTPUT_FILE="$OUTPUT_DIR/workshop-kubeconfig.yaml"

mkdir -p "$OUTPUT_DIR"

echo "================================================"
echo "Generating workshop participant kubeconfig"
echo "================================================"
echo ""

# Get the current cluster API server
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
echo "API server: $SERVER"

# Read token and CA from the SA secret
TOKEN=$(kubectl get secret "$SECRET_NAME" -n "$SA_NAMESPACE" -o jsonpath='{.data.token}' | base64 -d)
CA=$(kubectl get secret "$SECRET_NAME" -n "$SA_NAMESPACE" -o jsonpath='{.data.ca\.crt}')

if [ -z "$TOKEN" ]; then
  echo "ERROR: Token not found in secret $SECRET_NAME. Is the ServiceAccount deployed?"
  exit 1
fi

# Build the kubeconfig
cat > "$OUTPUT_FILE" <<EOF
apiVersion: v1
kind: Config
clusters:
  - name: workshop
    cluster:
      server: ${SERVER}
      certificate-authority-data: ${CA}
contexts:
  - name: workshop
    context:
      cluster: workshop
      user: workshop-participant
users:
  - name: workshop-participant
    user:
      token: ${TOKEN}
current-context: workshop
EOF

echo ""
echo "Generated: $OUTPUT_FILE"
echo ""
echo "To test:"
echo "  export KUBECONFIG=$OUTPUT_FILE"
echo "  kubectl get namespaces"
echo ""
echo "Distribute this file to all workshop participants."
