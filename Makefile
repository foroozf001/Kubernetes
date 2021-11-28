SHELL:=/bin/bash
.ONESHELL:
# Provision a multi-node Kubernetes cluster.
cluster:
	kind create cluster --config=setup/config.yaml
	# https://docs.projectcalico.org/getting-started/kubernetes/self-managed-onprem/onpremises#install-calico-on-nodes 
	kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
	kubectl -n kube-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true
	kubectl rollout status ds/calico-node -n kube-system
	# https://kind.sigs.k8s.io/docs/user/loadbalancer/
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$$(openssl rand -base64 128)" 
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
	kubectl apply -f setup/metallb.cm.yaml
	kubectl rollout status deploy/controller -n metallb-system
	# https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/baremetal/deploy.yaml
	kubectl patch svc ingress-nginx-controller --namespace=ingress-nginx --type=json -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'
	kubectl rollout status deploy/ingress-nginx-controller -n ingress-nginx

awx: cluster
	sudo rm -rf awx-operator
	git clone https://github.com/ansible/awx-operator.git
	cp services/awx/awx.yaml awx-operator/awx.yaml
	cd awx-operator/
	git checkout tags/0.15.0 -b tags/0.15.0
	make deploy
	kubectl rollout status deploy/awx-operator-controller-manager -n awx
	kubectl apply -f awx.yaml
	TODO: wait for awx operator to exist before proceeding
	retries=2
	until [[ "$${retries}" == 0 ]];do
		echo "[info] waiting..."
		sleep 30
		retries=$$((retries - 1))
	done
	kubectl rollout status deploy/awx-demo -n awx
	LB_IP=$$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	if [[ -z $$(grep "$$LB_IP ansible.local.vodafoneziggo.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP ansible.local.vodafoneziggo.com"
		sudo bash -c "echo '"$${LB_IP}" ansible.local.vodafoneziggo.com' >> /etc/hosts"
	fi
	echo "[info] user:admin password:"
	kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode; echo

gitlab: cluster
	GL_OPERATOR_VERSION=0.1.0
	PLATFORM=kubernetes
	kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.1/cert-manager.yaml
	kubectl rollout status deploy/cert-manager -n cert-manager
	# TODO: wait for validate webhook to exist before proceeding
	retries=2
	until [[ "$${retries}" == 0 ]];do
		echo "[info] waiting..."
		sleep 30
		retries=$$((retries - 1))
	done
	kubectl create namespace gitlab-system
	kubectl apply -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/$${GL_OPERATOR_VERSION}/gitlab-operator-$${PLATFORM}-$${GL_OPERATOR_VERSION}.yaml
	# TODO: wait for gitlab operator to exist before proceeding
	retries=2
	until [[ "$${retries}" == 0 ]];do
		echo "[info] waiting..."
		sleep 30
		retries=$$((retries - 1))
	done
	kubectl apply -f services/gitlab/gitlab.yaml -n gitlab-system
	unset GL_OPERATOR_VERSION
	unset PLATFORM
	retries=50
	until [[ "$${retries}" == 0 ]];do
		STATUS=$$(kubectl get gitlabs/gitlab -n gitlab-system -o jsonpath='{.status.phase}')
		if [[ "$${STATUS}" == "Running" ]];then
			echo "[info] ready!"
			break
		else
			echo "[info] $$retries - waiting..."
		fi
		sleep 30
		retries=$$((retries - 1))
	done
	LB_IP=$$(kubectl get svc gitlab-nginx-ingress-controller -n gitlab-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	if [[ -z $$(grep "$$LB_IP gitlab.local.vodafoneziggo.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP gitlab.local.vodafoneziggo.com"
		sudo bash -c "echo '"$${LB_IP}" gitlab.local.vodafoneziggo.com' >> /etc/hosts"
	fi
	if [[ -z $$(grep "$$LB_IP minio.local.vodafoneziggo.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP minio.local.vodafoneziggo.com"
		sudo bash -c "echo '"$${LB_IP}" minio.local.vodafoneziggo.com' >> /etc/hosts"
	fi
	if [[ -z $$(grep "$$LB_IP registry.local.vodafoneziggo.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP registry.local.vodafoneziggo.com"
		sudo bash -c "echo '"$${LB_IP}" registry.local.vodafoneziggo.com' >> /etc/hosts"
	fi
	echo "[info] user:root password:"
	kubectl -n gitlab-system get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode; echo
	
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
	wordpressPassword=$$(kubectl get secret wp001-wordpress -n wp001 -o jsonpath='{.data.wordpress-password}' | base64 --decode)
	helm upgrade wp001 bitnami/wordpress -f services/wordpress/values.yaml -n wp001 --set wordpressPassword=password --set ingress.tls=true
	LB_IP=$$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
	if [[ -z $$(grep "$$LB_IP my.wordpress.com" "/etc/hosts") ]];then 
		echo "[info] add DNS: $$LB_IP my.wordpress.com"
		sudo bash -c "echo '"$${LB_IP}" my.wordpress.com' >> /etc/hosts"
	fi

clean:
	kind delete cluster