# Provision a Kind-cluster with Metallb loadbalancing solution and an Nginx Ingress controller.
cluster:
	kind create cluster --config=setup/config.yaml

	# https://kind.sigs.k8s.io/docs/user/loadbalancer/
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml
	kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)" 
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
	kubectl apply -f setup/metallb.cm.yaml

	# https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/baremetal/deploy.yaml
	kubectl patch svc ingress-nginx-controller --namespace=ingress-nginx --type=json -p '[{"op":"replace","path":"/spec/type","value":"LoadBalancer"}]'

clean:
	kind delete cluster