# KiND

KiND allows for easy provisioning of multi-node clusters. Where a traditional Kubernetes cluster runs on VMs, a KiND cluster runs on Docker containers. The advantage of KiND is that it spins up incredibly fast compared to a VM cluster. The downside to KiND is that the nodes are bare minimum, meaning they install only the bare essentials to run a Kubernetes cluster. Commonly needed tools like ```nslookup```, ```wget```, ```curl``` and ```netcat``` are unavailable on the nodes. It's possible however, to spin up a Busybox image containing all the aforementioned tools. Another downside is that you'll need to expose web services via NodePorts.

## Prerequisites
* [Docker](https://docs.docker.com/engine/install/)
* [KiND](https://kind.sigs.k8s.io/)

## Step-by-step
1. Spin up a multi-node cluster using the KiND configurations file.
```bash
$ kind create cluster --config config.yml
Creating cluster "cdaas" ...
 ✓ Ensuring node image (kindest/node:v1.21.1) 🖼
 ✓ Preparing nodes 📦 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
Set kubectl context to "kind-cdaas"
You can now use your cluster with:

kubectl cluster-info --context kind-cdaas

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
```
2. Check cluster availability.
```bash
$ kubectl cluster-info --context kind-cdaas
Kubernetes control plane is running at https://127.0.0.1:40509
CoreDNS is running at https://127.0.0.1:40509/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
3. For example, run Nginx web server.
```bash
$ kubectl run nginx --image=nginx
pod/nginx created
```
4. Expose the pod on port 30080, which is mapped to hostport 30080.
```bash
$ kubectl expose po nginx --port=80 --name=nginx --type=NodePort
service/nginx exposed
$ kubectl patch svc nginx -p '{"spec": {"ports": [{"name": "nginx", "port": 80, "nodePort": 30080}]}}'
service/nginx patched
```
5. Access the Nginx web server from localhost.
```bash
$ curl localhost:30080
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```
6. Cleanup KiND cluster.
```bash
$ kind delete cluster --name=cdaas
Deleting cluster "cdaas" ...
```