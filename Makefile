# Provision a multi-node Kubernetes cluster.
cluster:
	setup/setup.sh

dashboard:
	services/kubernetes-dashboard/setup.dashboard.sh

clean:
	kind delete cluster