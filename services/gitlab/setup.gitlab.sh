#!/bin/bash
# Set environment variables
GL_OPERATOR_VERSION=0.1.0
PLATFORM=kubernetes

# Install cert-manager
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.1/cert-manager.yaml
kubectl rollout status deploy/cert-manager -n cert-manager
# TODO: wait for validate webhook to come up instead of sleeping
retries=2
until [[ "${retries}" == 0 ]];do
  echo "[info] timeout $retries..."
  sleep 30
  retries=$((retries - 1))
done

# Install gitlab
kubectl create namespace gitlab-system
kubectl apply -f https://gitlab.com/api/v4/projects/18899486/packages/generic/gitlab-operator/${GL_OPERATOR_VERSION}/gitlab-operator-${PLATFORM}-${GL_OPERATOR_VERSION}.yaml

# TODO: wait for gitlab operator to come up
retries=2
until [[ "${retries}" == 0 ]];do
  echo "[info] timeout $retries..."
  sleep 30
  retries=$((retries - 1))
done

kubectl apply -f services/gitlab/gitlab.yaml -n gitlab-system

# Remove environment variables
unset GL_OPERATOR_VERSION
unset PLATFORM

# Check gitlab operator readiness
retries=50
until [[ "${retries}" == 0 ]];do
  STATUS=$(kubectl get gitlabs/gitlab -n gitlab-system -o jsonpath='{.status.phase}')
  if [[ "${STATUS}" == "Running" ]];then
    echo "[info] ready!"
    break
  else
    echo "[info] timeout ${retries}..."
  fi
  sleep 30
  retries=$((retries - 1))
done

# Add local gitlab DNS records
LB_IP=$(kubectl get svc gitlab-nginx-ingress-controller -n gitlab-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [[ -z $(grep "$LB_IP gitlab.local.vodafoneziggo.com" "/etc/hosts") ]];then 
  echo "[info] add DNS: $LB_IP gitlab.local.vodafoneziggo.com"
  sudo bash -c "echo '172.18.255.201 gitlab.local.vodafoneziggo.com' >> /etc/hosts"
fi
if [[ -z $(grep "$LB_IP minio.local.vodafoneziggo.com" "/etc/hosts") ]];then 
  echo "[info] add DNS: $LB_IP minio.local.vodafoneziggo.com"
  sudo bash -c "echo '172.18.255.201 minio.local.vodafoneziggo.com' >> /etc/hosts"
fi
if [[ -z $(grep "$LB_IP registry.local.vodafoneziggo.com" "/etc/hosts") ]];then 
  echo "[info] add DNS: $LB_IP registry.local.vodafoneziggo.com"
  sudo bash -c "echo '172.18.255.201 registry.local.vodafoneziggo.com' >> /etc/hosts"
fi

# Fetch admin credentials
echo "[info] user:root password:"
kubectl -n gitlab-system get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode; echo

exit 0