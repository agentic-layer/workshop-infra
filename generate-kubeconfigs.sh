#!/bin/bash

# Script to generate kubeconfig files for all vClusters
# These files can be distributed to workshop participants for external access

set -e

# Configuration
CLUSTERS_COUNT=4
OUTPUT_DIR="kubeconfigs"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "================================================"
echo "Generating kubeconfig files for vClusters"
echo "================================================"
echo ""

# Generate kubeconfig for each vCluster
for i in $(seq 1 $CLUSTERS_COUNT); do
  VCLUSTER_NAME="vcluster-$i"
  NAMESPACE="vcluster-$i"
  OUTPUT_FILE="$OUTPUT_DIR/participant-$i-kubeconfig.yaml"

  echo "Processing $VCLUSTER_NAME..."

  # Get the external IP
  EXTERNAL_IP=$(kubectl get svc $VCLUSTER_NAME -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

  if [ -z "$EXTERNAL_IP" ]; then
    echo "  ✗ ERROR: No external IP found for $VCLUSTER_NAME"
    continue
  fi

  echo "  External IP: $EXTERNAL_IP"
  echo "  Generating kubeconfig..."

  # Generate kubeconfig using vcluster CLI
  vcluster connect $VCLUSTER_NAME -n $NAMESPACE \
    --server=https://$EXTERNAL_IP \
    --print > "$OUTPUT_FILE"

  echo "  ✓ Generated: $OUTPUT_FILE"
  echo ""
done

echo "================================================"
echo "Summary"
echo "================================================"
echo "Generated kubeconfig files in $OUTPUT_DIR/:"
ls -lh "$OUTPUT_DIR"/*.yaml
echo ""
echo "To test a kubeconfig:"
echo "  export KUBECONFIG=$OUTPUT_DIR/participant-1-kubeconfig.yaml"
echo "  kubectl get nodes"
echo ""
echo "Distribute these files to workshop participants!"
