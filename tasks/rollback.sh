#!/bin/bash

set -ex

echo $APP_NAME

export HOME=$(pwd)
CERT_DIR=${HOME}/credentials
mkdir -p ${CERT_DIR}
CA_PEM="${CERT_DIR}/ca.pem"
ADMIN_PEM="${CERT_DIR}/admin.pem"
ADMIN_KEY_PEM="${CERT_DIR}/admin-key.pem"

set +x
echo "${KUBE_CLUSTER_CA}" > ${CA_PEM}
echo "${KUBE_CLIENT_CERT}" > ${ADMIN_PEM}
echo "${KUBE_CLIENT_KEY}" > ${ADMIN_KEY_PEM}
chmod 600 ${CA_PEM}
chmod 600 ${ADMIN_PEM}
chmod 600 ${ADMIN_KEY_PEM}
set -x

export KUBECONFIG=${HOME}/kubeconfig
cat << EOT > ${KUBECONFIG}
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: ${CA_PEM}
    server: ${KUBE_SERVER}
  name: target-cluster
contexts:
- context:
    cluster: target-cluster
    namespace: default
    user: ${KUBE_USER}
  name: target-context
users:
- name: ${KUBE_USER}
  user:
    client-certificate: ${ADMIN_PEM}
    client-key: ${ADMIN_KEY_PEM}
current-context: target-context
EOT

kubectl get namespace ${KUBE_NAMESPACE} || kubectl create namespace ${KUBE_NAMESPACE}

helm version

helm init -c

RN=$(helm list --deployed --failed --date --reverse | grep ${APP_NAME} | head -n 1 | cut -f 1)
RV=$(helm list --deployed --failed --date --reverse | grep ${APP_NAME} | head -n 1 | cut -f 2)

echo "RELEASE NAME = ${RN}, REVISION = ${RV}"
echo "RELEASE NAME = ${RN}, REVISION = ${RV}" >> ../../notify-message/text

if [ -z "${RN}" ]; then
  echo "release name is not found, fail rollback to ${KUBE_SERVER}"
  echo "release name is not found, fail rollback to ${KUBE_SERVER}" >> ../../notify-message/text
  exit -1;
elif [ "${RV}" != "1" ]; then
  RRV=$(expr $RV - 1)
  helm rollback ${RN} ${RRV} > /dev/null
  echo "helm rollback ${RN} ${RRV}" >> ../../notify-message/text
  echo "complete rollback to ${KUBE_SERVER}"
  exit 0;
else
  echo "invalid current revision: ${RN}, ${RV}, fail rollback to ${KUBE_SERVER}"
  echo "invalid current revision: ${RN}, ${RV}, fail rollback to ${KUBE_SERVER}" >> ../../notify-message/text
  exit -2;
fi
