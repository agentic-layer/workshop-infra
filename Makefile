GITHUB_USER ?= agentic-layer
GCP_PROJECT ?= agentic-layer-workshop
GCP_REGION ?= europe-west1
GCP_ZONE ?= europe-west1-b
CLUSTER_NAME ?= mother-vcluster

.PHONY: kubeconfigs

prepare-cluster:
	@gcloud config set compute/zone europe-west1-b
	@gcloud config set container/use_client_certificate False

create-cluster:
	@gcloud container clusters create $(CLUSTER_NAME)-$(GCP_REGION)  \
		--addons HttpLoadBalancing,HorizontalPodAutoscaling,ConfigConnector \
		--workload-pool=$(GCP_PROJECT).svc.id.goog \
		--enable-autoscaling \
		--autoscaling-profile=optimize-utilization \
		--num-nodes=1 \
		--min-nodes=1 --max-nodes=5 \
		--machine-type=n1-standard-8 \
        --accelerator type=nvidia-tesla-t4,count=1 \
        --local-ssd-count=1 \
		--logging=SYSTEM \
    	--monitoring=SYSTEM \
		--region=$(GCP_REGION) \
		--release-channel=stable \
		--cluster-version=1.33
	@kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$$(gcloud config get-value core/account)
	@kubectl cluster-info

bootstrap-flux:
	@flux bootstrap github \
		--owner=$(GITHUB_USER) \
  		--repository=workshop-infra \
  		--branch=main \
  		--path=./clusters/$(CLUSTER_NAME)-$(GCP_REGION) \
		--read-write-key \
  		--personal

secrets:
	@kubectl create namespace showcase-news && \
	@kubectl create secret generic api-key-secrets \
		--namespace=showcase-news \
		--from-literal=OPENAI_API_KEY=${WORKSHOP_OPENAI_API_KEY} \
		--from-literal=GEMINI_API_KEY=${WORKSHOP_GEMINI_API_KEY}

kubeconfigs:
	rm -rf kubeconfigs/ && rm -fr kubeconfigs-encrypted/ && \
	sh generate-kubeconfigs.sh && \
	sh encrypt-kubeconfigs.sh ${WORKSHOP_PASSWORD}

generate-vcluster-configs:
	@cd infrastructure/vcluster && ./generate-overlays.sh

delete-cluster:
	@gcloud container clusters delete $(CLUSTER_NAME) --region=$(GCP_REGION) --async --quiet

