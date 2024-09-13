#!/bin/bash

# Initial settings
OCP_RELEASE="4.16.4"  # OpenShift version
LOCAL_REGISTRY="172.18.109.61:8443"  # Local registry hostname and port
LOCAL_REPOSITORY="ocp4/openshift4"  # Local repository path to store images
PRODUCT_REPO="openshift-release-dev"
RELEASE_NAME="ocp-release"
LOCAL_SECRET_JSON='../pullsecret'  # Path to pull secret file
TLS_CERT_DIR="/opt/quay/certs"  # Directory where SSL certificates are stored
ARCHITECTURE=x86_64

# Ensure the SSL certificate is trusted by oc
export SSL_CERT_FILE="$TLS_CERT_DIR/ssl.cert"

# Log in to the local registry
echo "Logging in to the local registry..."
podman login 172.18.109.61:8443 -u ocp4 -p Iahoora@123  --authfile ${LOCAL_SECRET_JSON}
#oc registry login --registry=$LOCAL_REGISTRY --auth-basic=admin:Iahoora@123 --insecure=true

# Mirror OpenShift release images to the local registry
echo "Mirroring OpenShift release images to the local registry..."
oc adm release mirror \
    --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-x86_64 \
    --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
    --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-x86_64 \
    --insecure=true \
    --registry-config=${LOCAL_SECRET_JSON} \
    --print-mirror-instructions=idms

#quay.io/openshift-release-dev/ocp-v4.0-art-dev
# Mirror additional OpenShift images from ocp-v4.0-art-dev
echo "Mirroring OpenShift ocp-v4.0-art-dev images to the local registry..."
oc adm release mirror \
    --from=quay.io/openshift-release-dev/ocp-v4.0-art-dev:${OCP_RELEASE}-x86_64 \
    --to=${LOCAL_REGISTRY}/ocp4/ocp-v4.0-art-dev \
    --insecure=true \
    --registry-config=${LOCAL_SECRET_JSON} \
    --print-mirror-instructions=idms
	
	
echo "Mirror process completed successfully."

oc adm release extract -a ${LOCAL_SECRET_JSON} --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"
sudo mv openshift-install /usr/bin/openshift-install
