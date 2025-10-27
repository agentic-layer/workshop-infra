# workshop-infra
Infrastructure for our Conference Workshops ("Architecting and Building a K8s-based AI Platform")


Based on https://github.com/lreimer/k8s-native-iac 's Makefile

## Prerequisites

Requires the following tools:
- kubectl
- gcloud CLI
- flux CLI
- **vcluster** CLI



## Setup

### 1. Create the Host Cluster
```bash
make prepare-cluster
make create-cluster
make bootstrap-flux
```

### 2. Generate vCluster Configurations
The number of vClusters can be configured by editing `clustersToCreate` in `generate-overlays.sh`:

```bash
make generate-vcluster-configs
git add infrastructure/vcluster/overlays
```

---

## Connect


### From Within the Host Cluster (Internal Access)
```bash
vcluster connect vcluster-1 -n vcluster-1

# This creates a local kubeconfig entry and switches context
kubectl get nodes
```

### From External Clients (Remote Access)
(TODO)

### Share Credentials with Workshop Participants
(TODO)


### Connecting to Specific vClusters
```bash
# List all vClusters
vcluster list

# Connect to a specific vCluster
vcluster connect vcluster-2 -n vcluster-2
vcluster connect vcluster-3 -n vcluster-3
vcluster connect vcluster-4 -n vcluster-4

# Disconnect (switches back to previous context)
vcluster disconnect
```


