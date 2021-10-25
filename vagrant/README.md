# Vagrant

Vagrant allows for provisioning of multi-node clusters on virtual machines using VirtualBox. The advantage of using traditional VMs is that it represents a production-like environment more closely and it allows users to install custom command-line tools. The downside of using a Vagrant cluster is that it takes longer to setup and requires higher resources from the host machine. 

## Prerequisites
* VirtualBox
* Ansible

## Step-by-step
1. Bringing up the Vagrant cluster is as simple as running a command. Vagrant will bootstrap the nodes using Ansible playbooks in the ```kubernetes-setup``` directory. The worker nodes will be automatically joined to the master node.
```bash
$ vagrant up
Bringing machine 'k8s-master' up with 'virtualbox' provider...
Bringing machine 'k8s-worker-1' up with 'virtualbox' provider...
```
2. SSH into the master node and check cluster availability.
```bash
$ vagrant ssh k8s-master
Welcome to Ubuntu 18.04.5 LTS (GNU/Linux 4.15.0-151-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Mon Oct 25 13:58:48 UTC 2021

  System load:  0.33              Users logged in:      0
  Usage of /:   6.2% of 61.80GB   IP address for eth0:  10.0.2.15
  Memory usage: 12%               IP address for eth1:  192.168.50.10
  Swap usage:   0%                IP address for tunl0: 172.16.235.192
  Processes:    163


This system is built by the Bento project by Chef Software
More information can be found at https://github.com/chef/bento
Last login: Mon Oct 25 13:53:35 2021 from 10.0.2.2
```
```bash
vagrant@k8s-master:~$ kubectl cluster-info --context kubernetes-admin@kubernetes
Kubernetes control plane is running at https://192.168.50.10:6443
CoreDNS is running at https://192.168.50.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
3. Inspect worker node availability.
```bash
vagrant@k8s-master:~$ kubectl get no -w
NAME           STATUS   ROLES                  AGE     VERSION
k8s-master     Ready    control-plane,master   8m46s   v1.21.0
k8s-worker-1   Ready    <none>                 6m3s    v1.21.0
```