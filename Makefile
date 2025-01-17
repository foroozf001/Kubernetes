MAKEFLAGS += --silent
SHELL:=/bin/bash
.ONESHELL:
.PHONY: cluster awx gitlab dashboard wordpress clean

# Provision a multi-node Kubernetes cluster.
cluster:
	# kind create cluster --config=setup/config.yaml
	# https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-on-nodes 
	kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
	kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
	kubectl rollout status ds/calico-node -n kube-system
	# https://kind.sigs.k8s.io/docs/user/loadbalancer/
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$$(openssl rand -base64 128)" 
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
	kubectl apply -f setup/metallb.cm.yaml
	kubectl rollout status deploy/controller -n metallb-system
	# https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/baremetal/deploy.yaml
	kubectl patch svc ingress-nginx-controller --namespace=ingress-nginx --type=json -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'
	kubectl rollout status deploy/ingress-nginx-controller -n ingress-nginx
	
dashboard: cluster
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
	kubectl rollout status deploy/kubernetes-dashboard -n kubernetes-dashboard
	kubectl apply -f services/kubernetes-dashboard/ingress.dashboard.yaml
	kubectl create clusterrolebinding kubernetes-dashboard-viewer --clusterrole=view --serviceaccount=kubernetes-dashboard:kubernetes-dashboard -n kubernetes-dashboard
	BEARER_TOKEN=$$(kubectl get secret -n kubernetes-dashboard -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -i kubernetes-dashboard-token)
	echo
	echo "Bearer token:"
	kubectl get secret "$${BEARER_TOKEN}" -n kubernetes-dashboard  -o jsonpath='{.data.token}' | base64 --decode; echo 
	echo
	unset BEARER_TOKEN
	LB_IP=$$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	if [[ -z $$(grep "$$LB_IP dashboard.local.vodafoneziggo.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP dashboard.local.vodafoneziggo.com"
		sudo bash -c "echo '"$${LB_IP}" dashboard.local.vodafoneziggo.com' >> /etc/hosts"
	fi

wordpress: cluster
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update
	kubectl apply -f services/wordpress/wordpress.yaml
	helm install wp001 bitnami/wordpress -f services/wordpress/values.yaml -n wp001
	kubectl rollout status deploy wp001-wordpress -n wp001
	helm upgrade wp001 bitnami/wordpress -f services/wordpress/values.yaml -n wp001 --set wordpressPassword=password --set ingress.tls=true
	LB_IP=$$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	if [[ -z $$(grep "$$LB_IP my.wordpress.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP my.wordpress.com"
		sudo bash -c "echo '"$${LB_IP}" my.wordpress.com' >> /etc/hosts"
	fi

clean:
	kind delete cluster