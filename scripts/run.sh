#!/bin/bash

#   $1 - ENTITLED_REGISTRY_PASSWORD - the key for the entitled registry (https://myibm.ibm.com/products-services/containerlibrary)
#   $2 - APIKEY - IBM Cloud API key
#   $3 - CLUSTER - The cluster ID
#   $4 - Absolute path of the data/ directory on the host machine

CP4APPS_VERSION="4.2.1"

# Disable checking for updates on the ibmcloud cli
ibmcloud config --check-version=false

# Log into IBM Cloud
ibmcloud login --apikey "$2" -r us-south

# Get the cluster config
# ibmcloud ks cluster config -c "$3"

ibmcloud ks cluster config --output yaml -c "$3" > cluster.yaml

# ibmcloud ks cluster config --output yaml -c bt7ug1td0qvrjicr8im0 > cluster.yaml

OPENSHIFT_URL=$(grep -A2 'clusters:' cluster.yaml | tail -n1 | awk '{ print $2}')

# Log into the entitled registry to get Cloud Pak Software
docker login cp.icr.io -u cp -p "$1"

docker run -u 0 -t \
        -e LICENSE=accept \
        -e ENTITLED_REGISTRY=cp.icr.io -e ENTITLED_REGISTRY_USER=cp -e ENTITLED_REGISTRY_KEY="$1" \
        -e OPENSHIFT_USERNAME="apikey" -e OPENSHIFT_PASSWORD="$2" -e OPENSHIFT_URL="$OPENSHIFT_URL" "cp.icr.io/cp/icpa/icpa-installer:${CP4APPS_VERSION}" check

# Get the data config if it does not exist
if [ $? == 0 ] && [ ! -d "/data" ]; then
    echo "data/ directory not found. Downloading configuration files."
    mkdir /data
    docker run -v $4/data:/data:z -u 0 \
        -e LICENSE=accept \
        "cp.icr.io/cp/icpa/icpa-installer:${CP4APPS_VERSION}" cp -r "data/*" /data
else
    echo "data/ directory already exists. Skipping download."
fi

# Install CP4Apps
if [ $? == 0 ]; then
    docker run -u 0 -t \
        -v $4/data:/installer/data:z \
        -e LICENSE=accept \
        -e ENTITLED_REGISTRY=cp.icr.io -e ENTITLED_REGISTRY_USER=cp -e ENTITLED_REGISTRY_KEY="$1" \
        -e OPENSHIFT_USERNAME="apikey" -e OPENSHIFT_PASSWORD="$2" -e OPENSHIFT_URL="$OPENSHIFT_URL" "cp.icr.io/cp/icpa/icpa-installer:4.2.1" install
else
    exit 1
fi
