# Vagrant

Vagrant allows for provisioning of multi-node clusters on virtual machines using VirtualBox. The advantage of using traditional VMs is that it represents a production-like environment more closely, and that it provides users much needed command-line tools like ```nslookup```, ```wget```, ```curl``` and ```netcat```. Another upside is that it allows for usage of Ingress. The downside of using a Vagrant cluster is that it takes longer to setup and requires higher resources from the host machine. 

## Prerequisites
* VirtualBox
* Ansible

## Step-by-step
1. Bringing up the Vagrant cluster is as simple as running a command. Vagrant will bootstrap the nodes using Ansible playbooks in the ```kubernetes-setup``` directory. The worker nodes will be automatically joined to the master node.
```bash
$ vagrant up
Bringing machine 'k8s-master' up with 'virtualbox' provider...
Bringing machine 'k8s-worker-1' up with 'virtualbox' provider...
Bringing machine 'k8s-worker-2' up with 'virtualbox' provider...
```
2. SSH into the master node and check cluster availability.
```bash
$ vagrant ssh k8s-master
Welcome to Ubuntu 20.04.2 LTS (GNU/Linux 5.4.0-80-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat 23 Oct 2021 11:05:30 AM UTC

  System load:  0.67              Users logged in:        0
  Usage of /:   6.1% of 61.31GB   IPv4 address for eth0:  10.0.2.15
  Memory usage: 44%               IPv4 address for eth1:  192.168.50.10
  Swap usage:   0%                IPv4 address for tunl0: 172.16.235.192
  Processes:    159


This system is built by the Bento project by Chef Software
More information can be found at https://github.com/chef/bento
Last login: Sat Oct 23 10:57:35 2021 from 10.0.2.2

vagrant@k8s-master:~$ kubectl cluster-info --context kubernetes-admin@kubernetes
Kubernetes control plane is running at https://192.168.50.10:6443
CoreDNS is running at https://192.168.50.10:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```
3. Inspect worker node availability.
```bash
vagrant@k8s-master:~$ kubectl get no 
NAME           STATUS   ROLES                  AGE     VERSION
k8s-master     Ready    control-plane,master   10m     v1.22.0
k8s-worker-1   Ready    <none>                 8m50s   v1.22.0
k8s-worker-2   Ready    <none>                 7m21s   v1.22.0
```
4. For example, run Nginx web server.
```bash
vagrant@k8s-master:~$ kubectl run nginx --image=nginx
pod/nginx created
```
5. Expose the pod on NodePort 30080.
```bash
vagrant@k8s-master:~$ kubectl expose po nginx --port=80 --name=nginx --type=NodePort
service/nginx exposed
vagrant@k8s-master:~$ kubectl patch svc nginx -p '{"spec": {"ports": [{"name": "nginx", "port": 80, "nodePort": 30080}]}}'
service/nginx patched
```
6. Install Nginx ingress controller ([source](https://kubernetes.github.io/ingress-nginx/deploy/#bare-metal)).
```bash
vagrant@k8s-master:~$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.4/deploy/static/provider/baremetal/deploy.yaml
namespace/ingress-nginx created
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created
```
7. Create ```ingress.yaml```.
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-web
  annotations:
    # use the shared ingress-nginx
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: example.internal.vodafoneziggo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
```
8. Deploy Ingress.
```bash
vagrant@k8s-master:~$ kubectl apply -f ingress.yaml
ingress.networking.k8s.io/ingress-web created
```
9. Inspect Ingress has external IP.
```bash
vagrant@k8s-master:~$ kubectl get ingress
NAME          CLASS    HOSTS                                ADDRESS         PORTS   AGE
ingress-web   <none>   example.internal.vodafoneziggo.com   192.168.50.12   80      25s
```
10. Exit k8s-master.
```bash
exit
```
11. Create custom DNS entry on localhost using Ingress' external IP.
```bash
$ sudo bash -c "echo '192.168.50.12 example.internal.vodafoneziggo.com' >> /etc/hosts"
```
12. Access the Nginx web server using the custom domain name.
```bash
$ curl example.internal.vodafoneziggo.com:30080
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