# workshop-infra
Infrastructure for our Conference Workshops ("Architecting and Building a K8s-based AI Platform")


Based on https://github.com/lreimer/k8s-native-iac 's Makefile

## Layout

Flux Kustomizations under `foundation/host-cluster/` are organized along
the conceptual planes used in the [agentic-layer
docs](https://docs.agentic-layer.ai/) and the workshop step folders:

| Path | Contents |
|---|---|
| `infrastructure/` | Kubernetes prerequisites: cert-manager, Gateway API CRDs |
| `observability-controllers/` | OpenTelemetry operator, Prometheus CRDs |
| `observability/` | LGTM stack (Loki, Grafana, Tempo, Mimir), OTel collector, observability-dashboard |
| `platform-operators/` | The four agentic-layer operators (agent-runtime, agent-gateway-krakend, ai-gateway-litellm, tool-gateway-agentgateway) |
| `platform-gateways/` | Gateway *instances* (Agent Gateway, AI Gateway, Tool Gateway) — Custom Resources reconciled by the operators above |
| `user-serving-plane/` | LibreChat, the chat UI participants point at the Agent Gateway |
| `quality-plane/` | testkube + testbench-operator: evaluating agents with Experiments |

Dependencies are wired so a cold cluster bootstraps cleanly:
`infrastructure → {observability-controllers, platform-operators} → {observability, platform-gateways} → {user-serving-plane, quality-plane}`.

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
- `source .env`
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
kubectl apply -f foundation/mother-vcluster-europe-west1/ollama-operator/ollama-model-llama31.yaml
kollama expose llama3.1 --service-name=ollama-model-llama31 --namespace ollama-operator-system
kollama expose llama3.1 --service-name=ollama-model-llama31-lb --service-type LoadBalancer --namespace ollama-operator-system

# to start a chat with ollama
# exchange localhost with the actual LoadBalancer IP
OLLAMA_HOST=localhost:11434 ollama run llama3.1

# call the chat API of Ollama or OpenAI
# curl http://ollama-model-llama31.default:11434/v1/chat/completions
curl http://ollama-model-llama31.default:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.1",
    "messages": [
      {
        "role": "user",
        "content": "Say this is a test!"
      }
    ]
  }'
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


