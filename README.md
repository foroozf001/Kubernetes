# Kubernetes
This repository contains scripts and instructions to provision local Kubernetes environments. 
## Kind

Kind allows provisioning multi-node clusters on Docker containers. The advantage of using Kind is that it represents a production-like environment closely and it provisions incredibly fast.

## Prerequisites
* Kind
* Docker

## Step-by-step
1. Determine your subnet for Kind from Docker. In this case it's ```172.18.0.0/16```. 
```bash
$ docker network inspect -f '{{.IPAM.Config}}' kind
[{172.18.0.0/16  172.18.0.1 map[]} {fc00:f853:ccd:e793::/64  fc00:f853:ccd:e793::1 map[]}]
```

2. From the Kind subnet we'll pick a sensible IP-range for Metallb to use (x.x.255.200-x.x.255.250). Update ```setup/metallb.cm.yaml``` accordingly.
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
3. Bringing up the Kind cluster is as simple as running the Makefile.
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