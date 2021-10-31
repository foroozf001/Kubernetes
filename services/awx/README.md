# AWX
This document describes how to provision AWX on a Kind Kubernetes cluster using the [AWX operator](https://github.com/ansible/awx-operator).
## Step-by-step
1. Clone the AWX operator repository.
```bash
$ git clone https://github.com/ansible/awx-operator.git
Cloning into 'awx-operator'...
remote: Enumerating objects: 5800, done.
remote: Counting objects: 100% (3014/3014), done.
remote: Compressing objects: 100% (1126/1126), done.
remote: Total 5800 (delta 2024), reused 2552 (delta 1786), pack-reused 2786
Receiving objects: 100% (5800/5800), 1.42 MiB | 3.69 MiB/s, done.
Resolving deltas: 100% (3305/3305), done.
```
2. Move into AWX operator working directory.
```bash
$ cd awx-operator/
```
3. Inspect AWX operator version tags.
```bash
$ git tag -l
0.10.0
0.11.0
0.12.0
0.13.0
0.14.0
0.6.0
0.7.0
0.8.0
0.9.0
```
4. Checkout AWX operator version tag.
```bash
$ git checkout tags/0.14.0 -b tags/0.14.0
Switched to a new branch 'tags/0.14.0'
```
5. Run AWX operator Makefile.
```bash
$ make deploy
```
6. Inspect AWX deployment for readiness.
```bash
$ kubectl get deploy -n awx -w
NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
awx-operator-controller-manager   0/1     1            0           15s
awx-operator-controller-manager   1/1     1            1           50s
```
7. Edit ```awx-demo.yaml```.
```yaml
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx-demo
  namespace: awx
spec:
  service_type: ClusterIP
  ingress_type: ingress
  ingress_annotations: |
    kubernetes.io/ingress.class: "nginx"
  hostname: ansible.local.vodafoneziggo.com
```
8. Deploy AWX.
```bash
$ kubectl apply -f awx-demo.yml
awx.awx.ansible.com/awx-demo created
```
9. Inspect AWX pods for readiness.
After some minutes.
```bash
$ kubectl get po -n awx
NAME                                               READY   STATUS    RESTARTS   AGE
awx-demo-d46576-7g9gd                              4/4     Running   0          4m6s
awx-demo-postgres-0                                1/1     Running   0          4m11s
awx-operator-controller-manager-68d787cfbd-q6shf   2/2     Running   0          7m8s                           4/4     Running             0          2m35s
```
10. Fetch ```admin``` credentials.
```bash
vagrant@k8s-m-1:~/awx-operator$ kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode; echo
I3UHCkULobfnZQNpqAgiF19xQIAxq1TN
```
11. Fetch IP of ```Nginx Ingress Controller``` service.
```bash
$ kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'; echo
172.18.255.200
```
12. Create custom DNS entry. The IP address is that of the ```Nginx Ingress Controller```.
```bash
$ sudo bash -c "echo '172.18.255.200 ansible.local.vodafoneziggo.com' >> /etc/hosts"
```
13. Access the AWX web server using the custom domain name and log in using ```admin``` credentials.
![awx](img/awx.png))