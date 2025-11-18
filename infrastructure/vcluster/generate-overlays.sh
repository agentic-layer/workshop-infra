#!/bin/bash

# Configuration
clustersToCreate=24

# Clean up previous generated files
rm -rf overlays
mkdir -p overlays

# The root kustomization file (references the HelmRepository and overlays)
cat <<EOF > kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - overlays
EOF

# Generate an overlay for each vCluster
for i in $(seq 1 $clustersToCreate)
do
  VCLUSTER_NAME="vcluster-$i"
  OVERLAY_DIR="overlays/$VCLUSTER_NAME"
  mkdir -p $OVERLAY_DIR

  # Create the namespace resource
  cat <<EOF > $OVERLAY_DIR/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $VCLUSTER_NAME
EOF

  # Create the kustomization.yaml for the overlay
  cat <<EOF > $OVERLAY_DIR/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: $VCLUSTER_NAME
resources:
  - namespace.yaml
  - ../../base

patches:
  - patch: |-
      - op: replace
        path: /metadata/name
        value: $VCLUSTER_NAME
      - op: replace
        path: /metadata/namespace
        value: $VCLUSTER_NAME
    target:
      kind: HelmRelease
      name: vcluster-template
EOF
done

# Create the overlays/kustomization.yaml that lists all overlays
cat <<EOF > overlays/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
EOF

for i in $(seq 1 $clustersToCreate)
do
  echo "  - vcluster-$i" >> overlays/kustomization.yaml
done

echo "Generated $clustersToCreate vCluster overlays."
