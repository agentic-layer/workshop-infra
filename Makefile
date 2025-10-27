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
		--owner=$(GITHUB_USER) \
  		--repository=k8s-native-iac \
  		--branch=main \
  		--path=./clusters/gke-cluster \
		--components-extra=image-reflector-controller,image-automation-controller \
		--read-write-key \
  		--personal

delete-cluster:
	@gcloud container clusters delete host-cluster --region=$(GCP_REGION) --async --quiet
