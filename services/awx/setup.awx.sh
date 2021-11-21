#!/bin/bash
# Clone locally awx-operator repository
git clone https://github.com/ansible/awx-operator.git
cd awx-operator/

# Checkout release tag
git checkout tags/0.14.0 -b tags/0.14.0
make deploy

# Wait for operator to come up
kubectl rollout status deploy/awx-operator-controller-manager -n awx

# Overwrite and deploy awx
cat << EOF > awx-demo.yml
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
EOF
kubectl apply -f awx-demo.yml

# TODO: wait for awx operator to come up
retries=2
until [[ "${retries}" == 0 ]];do
  echo "[info] timeout $retries..."
  sleep 30
  retries=$((retries - 1))
done

kubectl rollout status deploy/awx-demo -n awx

# Add local awx DNS records
LB_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ -z $(grep "$LB_IP ansible.local.vodafoneziggo.com" "/etc/hosts") ]];then 
  echo "[info] add DNS: $LB_IP ansible.local.vodafoneziggo.com"
  sudo bash -c "echo '172.18.255.200 ansible.local.vodafoneziggo.com' >> /etc/hosts"
fi

# Remove awx-operator repository
cd ..
sudo rm -rf awx-operator

# Fetch admin credentials
echo "[info] user:admin password:"
kubectl get secret awx-demo-admin-password -o jsonpath="{.data.password}" -n awx | base64 --decode; echo