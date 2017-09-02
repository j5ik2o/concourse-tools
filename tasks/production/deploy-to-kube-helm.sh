#!/bin/bash

set -ex

export HOME=$(pwd)
CERT_DIR=${HOME}/credentials
mkdir -p ${CERT_DIR}
CA_PEM="${CERT_DIR}/ca.pem"
ADMIN_PEM="${CERT_DIR}/admin.pem"
ADMIN_KEY_PEM="${CERT_DIR}/admin-key.pem"

set +x

echo "deploying for ${APP_VERSION}"
echo "${KUBE_CLUSTER_CA}" > ${CA_PEM}
echo "${KUBE_CLIENT_CERT}" > ${ADMIN_PEM}
echo "${KUBE_CLIENT_KEY}" > ${ADMIN_KEY_PEM}
chmod 600 ${CA_PEM}
chmod 600 ${ADMIN_PEM}
chmod 600 ${ADMIN_KEY_PEM}
set -x

APP_VERSION=$(cat ../../version-repo/VERSION)

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

helm init -c --skip-refresh

sed -i -e "s/##app_version##/${APP_VERSION}/" ${APP_NAME}/Chart.yaml
helm package ${APP_NAME}
RN=$(helm list --deployed --failed --date --reverse | grep ${APP_NAME} | grep -v "SNAPSHOT" | head -n 1 | cut -f 1)

echo "RELEASE NAME = ${RN}"
echo "RELEASE NAME = ${RN}" >> ../../notify-message/text

if [ "${RN}" != "" ]; then
  helm upgrade ${RN} local/${APP_NAME}-${APP_VERSION}.tgz --set imageRegistry=${IMAGE_REGISTRY},appVersion=${APP_VERSION},version=${APP_VERSION} > /dev/null
  echo "helm upgrade ${RN} local/${APP_NAME}-${APP_VERSION}.tgz --set imageRegistry=${IMAGE_REGISTRY},appVersion=${APP_VERSION},version=${APP_VERSION}" >> ../../notify-message/text
else
  helm install local/${APP_NAME}-${APP_VERSION}.tgz --namespace ${KUBE_NAMESPACE} --set imageRegistry=${IMAGE_REGISTRY},appVersion=${APP_VERSION},version=${APP_VERSION} > /dev/null
  echo "helm install local/${APP_NAME}-${APP_VERSION}.tgz --namespace ${KUBE_NAMESPACE} --set imageRegistry=${IMAGE_REGISTRY},appVersion=${APP_VERSION},version=${APP_VERSION}" >> ../../notify-message/text
fi

echo "complete deploy to ${KUBE_SERVER}"
exit 0;
