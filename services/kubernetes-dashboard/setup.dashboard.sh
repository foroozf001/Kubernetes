#!/bin/bash
LB_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "${LB_IP}"
if [[ ! -z "${LB_IP}" ]];then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.4.0/aio/deploy/recommended.yaml
  kubectl apply -f services/kubernetes-dashboard/ingress.dashboard.yaml
  kubectl create clusterrolebinding kubernetes-dashboard-viewer --clusterrole=view --serviceaccount=kubernetes-dashboard:kubernetes-dashboard -n kubernetes-dashboard
  BEARER_TOKEN=$(kubectl get secret -n kubernetes-dashboard -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | grep -i kubernetes-dashboard-token)
  echo
  echo "Bearer token:"
  kubectl get secret "${BEARER_TOKEN}" -n kubernetes-dashboard  -o jsonpath='{.data.token}' | base64 --decode; echo 
  unset BEARER_TOKEN
  echo
  echo "Create local DNS entry in /etc/hosts: ${LB_IP} dashboard.local.vodafoneziggo.com"
  unset LB_IP
else
  echo "$(tput setaf 1)Wait a moment for Nginx Ingress controller to come up..."
fi