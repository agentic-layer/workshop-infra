GITHUB_USER ?= felixk101
GCP_PROJECT ?= agentic-layer-workshop
GCP_REGION ?= europe-north1
GCP_ZONE ?= europe-north1-b


prepare-cluster:
	@gcloud config set compute/zone europe-west1-b
	@gcloud config set container/use_client_certificate False

create-cluster:
	@gcloud container clusters create host-cluster  \
		--addons HttpLoadBalancing,HorizontalPodAutoscaling,ConfigConnector \
		--workload-pool=$(GCP_PROJECT).svc.id.goog \
		--enable-autoscaling \
		--autoscaling-profile=optimize-utilization \
		--num-nodes=2 \
		--min-nodes=2 --max-nodes=5 \
		--machine-type=e2-standard-2 \
		--logging=SYSTEM \
    --monitoring=SYSTEM \
		--region=$(GCP_REGION) \
		--release-channel=stable \
		--cluster-version=1.33
	@kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$$(gcloud config get-value core/account)
	@kubectl cluster-info

bootstrap-flux:
	@flux bootstrap github \
		--owner=agentic-layer \
  		--repository=workshop-infra \
  		--branch=main \
  		--path=./clusters/host-cluster \
		--components-extra=image-reflector-controller,image-automation-controller \
		--read-write-key \
  		--personal

generate-vcluster-configs:
  infrastructure/vcluster/generate-overlays.sh

delete-cluster:
	@gcloud container clusters delete host-cluster --region=$(GCP_REGION) --async --quiet
