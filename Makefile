# Provision a multi-node Kubernetes cluster.
cluster:
	setup/setup.sh

awx: cluster
	services/awx/setup.awx.sh

gitlab: cluster
	services/gitlab/setup.gitlab.sh
	
dashboard: cluster
	services/kubernetes-dashboard/setup.dashboard.sh

clean:
	kind delete cluster