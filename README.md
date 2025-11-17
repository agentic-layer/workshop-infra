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

### 1. Create the Host Cluster, setup gitops
```bash
make prepare-cluster
make create-cluster
make bootstrap-flux
```

### 2. (Optional) Reconfigure vClusters

Edit the variable `clustersToCreate` in `generate-overlays.sh` to change the number of vClusters, then check in the changes:
```
make generate-vcluster-configs
git add infrastructure/vcluster/overlays/*
...
```

vCluster configuration can be changed later in `infrastructure/vcluster/base/vcluster.yaml`.

Note that changing the configuration might require the vClusters to be recreated, potentially breaking any credentials.

### 3. Setup env vars, secrets, and kubeconfigs 

- Copy `.env.example` to `.env`
- Configure environment variables based on entries in the [Google Secrets Manager](https://console.cloud.google.com/security/secret-manager?project=agentic-layer-workshop)
- Create secrets in the cluster
    ```
    make secrets
    ```
- Create vCluster KUBECONFIGs and encrypt them
    ```
    make kubeconfigs
    ```
- Copy the encrypted kubeconfigs to github.com/agentic-layer/workshop

### 4. Model Serving with Ollama

```bash
# llama3.1 model deployment via CRD
kubectl apply -f foundation/*/ollama-model-llama31.yaml
kollama expose llama3.1 --service-name=ollama-model-llama31-lb --service-type LoadBalancer
```

---

## Connect

### From External Clients (Remote Access)
```
./decrypt-kubeconfig.sh <path-to-encrypted-kubeconfig> <password> out.yaml
export KUBECONFIG=out.yaml
kubectl get nodes
```

### From Within the Host Cluster (Internal Access)
```bash
vcluster connect vcluster-1 -n vcluster-1

# This creates a local kubeconfig entry and switches context
kubectl get nodes
```

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


