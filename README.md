# Kubernetes
This repository contains scripts and instructions to provision local Kubernetes environments. 
## Kind
Kind allows provisioning multi-node clusters on Docker containers. The advantage of using Kind is that it closely represents production-like environments and it provisions incredibly fast.
## Prerequisites
* [Kind](https://kind.sigs.k8s.io/docs/user/quick-start/)
* [Docker](https://docs.docker.com/engine/install/debian/)
## Step-by-step
1. The Kind cluster runs on a custom Docker network: ```kind```. We require the Kind CIDR in order to allocate a narrow range of IPs to ```Metallb```. ```Metallb``` is a layer 7 load balancing solution for bare-metal Kubernetes clusters. Inspect the Kind network to determine the CIDR range.
```bash
$ docker network inspect -f '{{.IPAM.Config}}' kind
[{172.18.0.0/16  172.18.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]
```
2. From the CIDR range we pick a sensible IP-range for ```Metallb``` to use (..255.200-..255.250). These IPs will be dynamically allocated to Kubernetes ```LoadBalancer``` services. Update ```setup/metallb.cm.yaml``` according to the chosen IP range.
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 172.18.255.200-172.18.255.250 
```
3. Spinning up the Kind cluster is as simple as running the Makefile.
```bash
$ make cluster
kind create cluster --config=setup/config.yaml
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.21.1) 🖼
 ✓ Preparing nodes 📦 📦 📦  
 ✓ Writing configuration 📜 
 ✓ Starting control-plane 🕹️ 
 ✓ Installing CNI 🔌 
 ✓ Installing StorageClass 💾 
 ✓ Joining worker nodes 🚜 
```
4. Inspect worker node availability.
```bash
$ kubectl get no
NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   2m21s   v1.21.1
kind-worker          Ready    <none>                 105s    v1.21.1
kind-worker2         Ready    <none>                 105s    v1.21.1
```
5. Clean the Kind cluster.
```bash
$ make clean
kind delete cluster
Deleting cluster "kind" ...
```