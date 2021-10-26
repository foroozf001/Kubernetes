# Kubernetes
This repository contains scripts and instructions to provision local Kubernetes environments. For detailed explanation of the scripts, please refer to the source: https://www.itwonderlab.com/en/ansible-kubernetes-vagrant-tutorial/.
## Vagrant

Vagrant allows for provisioning of multi-node clusters on virtual machines using VirtualBox. The advantage of using traditional VMs is that it represents a production-like environment more closely and it allows users to install custom command-line tools. The downside of using a Vagrant cluster is that it takes a long time to setup and it requires higher resources from the host machine. 

## Prerequisites
* VirtualBox
* Ansible

## Step-by-step
1. Bringing up the Vagrant cluster is as simple as running a command. Vagrant will bootstrap the nodes using Ansible playbooks in the ```kubernetes-setup``` directory. The worker nodes will be automatically joined to the master node.
```bash
$ vagrant up
Bringing machine 'k8s-m-1' up with 'virtualbox' provider...
Bringing machine 'k8s-n-1' up with 'virtualbox' provider...
Bringing machine 'k8s-n-2' up with 'virtualbox' provider...
```
2. SSH into the master node and check cluster availability.
```bash
$ vagrant ssh k8s-m-1
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-80-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Tue 26 Oct 2021 05:42:08 PM UTC

  System load:  0.95              Users logged in:        0
  Usage of /:   6.5% of 61.31GB   IPv4 address for eth0:  10.0.2.15
  Memory usage: 43%               IPv4 address for eth1:  192.168.50.11
  Swap usage:   0%                IPv4 address for tunl0: 192.168.116.0
  Processes:    161


This system is built by the Bento project by Chef Software
More information can be found at https://github.com/chef/bento
Last login: Tue Oct 26 17:39:01 2021 from 10.0.2.2
```
3. Inspect worker node availability.
```bash
vagrant@k8s-m-1:~$ kubectl get no -w
NAME      STATUS   ROLES                  AGE     VERSION
k8s-m-1   Ready    control-plane,master   5m44s   v1.22.2
k8s-n-1   Ready    <none>                 3m9s    v1.22.2
k8s-n-2   Ready    <none>                 44s     v1.22.2
```
4. Edit the Nginx Ingress controller service type since the official manifests deploy type ```NodePort``` by default. Only change the value from ```NodePort``` to ```LoadBalancer```.
```bash
vagrant@k8s-m-1:~$ kubectl edit svc ingress-nginx-controller -n ingress-nginx
service/ingress-nginx-controller edited
```
5. Inspect Nginx Ingress controller service to have an external IP.
```bash
vagrant@k8s-m-1:~$ kubectl get svc ingress-nginx-controller -n ingress-nginx
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   10.108.12.140   192.168.50.240   80:31168/TCP,443:30907/TCP   6m23s
```