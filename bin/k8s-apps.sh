#!/bin/bash

#
# Install base applications to Kubernetes cluster.
#

# expand variables and print commands
set -x

function print_apps_help() {
  echo "\
usage: $0 <action> <app> <option>
  actions: deploy, delete
  apps: cat, elk, nfs, all
  -c [config file]  Specify config file.
  -h|--help         Print this help message.
"
}

if [[ $# = 0 ]]; then
  print_apps_help
  exit 1
fi

while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
    -h|--help)
      print_apps_help
      exit 0
      ;;
    deploy)
      APPS_ACTION="deploy"
      APP="$2"
      shift # past argument
      ;;
    delete)
      APPS_ACTION="delete"
      APP="$2"
      shift # past argument
      ;;
    loadFunctions)
      echo "just loading functions"
      APPS_ACTION="loadFunctions"
      ;;
    -c)
      CLUSTER_CONFIG="$2"
      shift
      ;;
    *)
      # unknown option
      print_apps_help
      exit 1
      ;;
  esac
  shift # past argument or value
done


# To override the variables below you can can export them out in a file and
# then set the variable "CLUSTER_CONFIG" to the location of that file.
# Setting at least CLUSTER_NAME, e.g., "pjl-stage", would be good for developer
# testing.

if  [ "${APPS_ACTION}" != "loadFunctions" ]
then
  if  [ -z ${CLUSTER_CONFIG+x} ]
  then
    echo "Using values from shell or defaults in this script."
  else
    echo "k8s-apps: Sourcing ${CLUSTER_CONFIG}"
    source ${CLUSTER_CONFIG}
  fi
fi

# MacOS does not support readlink, but it does have perl
KERNEL_NAME=$(uname -s)
if [ "${KERNEL_NAME}" = "Darwin" ]; then
  SCRIPT_PATH=$(perl -e 'use Cwd "abs_path";use File::Basename;print dirname(abs_path(shift))' "$0")
else
  SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
fi

#
# default user-definable variable definitions
#
NAMESPACE=${NAMESPACE-"default"}
PROJECT=${PROJECT-"A_GOOGLE_PROJECT_ID"}
REGION=${REGION-"us-east1"}
ZONE_EXTENSION=${ZONE_EXTENSION-b}
AVAILABILITY_ZONE=${AVAILABILITY_ZONE-${REGION}-${ZONE_EXTENSION}}
ENVIRONMENT=${ENVIRONMENT-"dev"}
PV_PREFIX=${PV_PREFIX-"$ENVIRONMENT-$USER-"}
HELXPLATFORM_HOME=${HELXPLATFORM_HOME-"../.."}
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-"${HELXPLATFORM_HOME}/devops"}
GKE_DEPLOYMENT=${GKE_DEPLOYMENT-false}

GCE_NFS_SERVER_DISK=${GCE_NFS_SERVER_DISK-"${PV_PREFIX}stdnfs-disk"}
GCE_NFS_SERVER_STORAGE=${GCE_NFS_SERVER_STORAGE-"10Gi"}

NFS_CLNT_PV_NFS_PATH=${NFS_CLNT_PV_NFS_PATH-"/exports"}
NFS_CLNT_PV_NFS_SRVR=${NFS_CLNT_PV_NFS_SRVR-"nfs-server.default.svc.cluster.local"}
NFS_CLNT_PV_NAME=${NFS_CLNT_PV_NAME-"${PV_PREFIX}stdnfs-pv"}
NFS_CLNT_PVC_NAME=${NFS_CLNT_PVC_NAME-"stdnfs"}
NFS_CLNT_STORAGECLASS=${NFS_CLNT_STORAGECLASS-"stdnfs-sc"}

NEXTFLOW_PVC=${NEXTFLOW_PVC-"deepgtex-prp"}
NEXTFLOW_STORAGE_SIZE=${NEXTFLOW_STORAGE_SIZE-"5Gi"}

AMBASSADOR_HELM_DIR=${AMBASSADOR_HELM_DIR-"$K8S_DEVOPS_CORE_HOME/helx/charts/ambassador"}
USE_CLUSTER_ROLES=${USE_CLUSTER_ROLES-false}
NGINX_HELM_DIR=${NGINX_HELM_DIR="$K8S_DEVOPS_CORE_HOME/helx/charts/nginx"}
NGINX_SERVERNAME=${NGINX_SERVERNAME-"helx.helx-dev.renci.org"}
NGINX_IP=${NGINX_IP-""}
NGINX_TLS_SECRET=${NGINX_TLS_SECRET-""}
NGINX_TLS_KEY=${NGINX_TLS_KEY-""}
NGINX_TLS_CRT=${NGINX_TLS_CRT-""}
NGINX_TLS_CA_CRT=${NGINX_TLS_CA_CRT-""}
NGINX_DNS_RESOLVER=${NGINX_DNS_RESOLVER-""}
NGINX_SERVICE_TYPE=${NGINX_SERVICE_TYPE-"LoadBalancer"}
NGINX_INGRESS_HOST=${NGINX_INGRESS_HOST-""}
NGINX_INGRESS_CLASS=${NGINX_INGRESS_CLASS-""}

HELM=${HELM-helm}
COMMONSSHARE_NAME=${COMMONSSHARE_NAME-"commonsshare"}
APPSTORE_NAME=${APPSTORE_NAME-"appstore"}
CAT_HELM_DIR=${CAT_HELM_DIR-"${K8S_DEVOPS_CORE_HOME}/helx"}
CAT_USER_STORAGE_NAME=${CAT_USER_STORAGE_NAME-"stdnfs"}
CAT_PVC_STORAGE=${CAT_PVC_STORAGE-"10Gi"}
CAT_PD_NAME=${CAT_PD_NAME-"${PV_PREFIX}$CAT_USER_STORAGE_NAME-disk"}
CAT_PV_NAME=${CAT_PV_NAME-"${PV_PREFIX}$CAT_USER_STORAGE_NAME-pv"}
CAT_NFS_SERVER=${CAT_NFS_SERVER-""}
CAT_NFS_PATH=${CAT_NFS_PATH-""}
CAT_PV_STORAGECLASS=${CAT_PV_STORAGECLASS-"$CAT_USER_STORAGE_NAME-sc"}
CAT_PV_STORAGE_SIZE=${CAT_PV_STORAGE_SIZE-"10Gi"}
CAT_DISK_SIZE=${CAT_DISK_SIZE-"10GB"}
CAT_PV_ACCESSMODE=${CAT_PV_ACCESSMODE-"ReadWriteMany"}

APPSTORE_OAUTH_PD_NAME=${APPSTORE_OAUTH_PD_NAME-"${PV_PREFIX}appstore-oauth-disk"}
APPSTORE_OAUTH_PV_NAME=${APPSTORE_OAUTH_PV_NAME-"${PV_PREFIX}appstore-oauth-pv"}
# Definie APPSTORE_OAUTH_PVC to use a PVC for the oauth sqlite3 db storage.
APPSTORE_OAUTH_PVC=${APPSTORE_OAUTH_PVC-""}
# Define APPSTORE_OAUTH_PV_STORAGECLASS to create a PVC and not use one already
# created.
APPSTORE_OAUTH_PV_STORAGECLASS=${APPSTORE_OAUTH_PV_STORAGECLASS-""}
APPSTORE_OAUTH_NFS_SERVER=${APPSTORE_OAUTH_NFS_SERVER-$CAT_NFS_SERVER}
APPSTORE_OAUTH_NFS_PATH=${APPSTORE_OAUTH_NFS_PATH-""}
APPSTORE_OAUTH_PV_STORAGE_SIZE=${APPSTORE_OAUTH_PV_STORAGE_SIZE-"10Gi"}
APPSTORE_OAUTH_PV_ACCESSMODE=${APPSTORE_OAUTH_PV_ACCESSMODE-"ReadWriteOnce"}
APPSTORE_IMAGE=${APPSTORE_IMAGE-""}
APPSTORE_IMAGE_PULL_SECRETS=${APPSTORE_IMAGE_PULL_SECRETS-""}
TYCHO_NAME=${TYCHO_NAME-"tycho"}
TYCHO_API_SERVICE_TYPE=${TYCHO_API_SERVICE_TYPE-""}
TYCHO_API_IMAGE=${TYCHO_API_IMAGE-""}
TYCHO_USE_ROLE=${TYCHO_USE_ROLE-""}

# Set DYNAMIC_NFSCP_DEPLOYMENT to false if NFS storage is not available (GKE).
DYNAMIC_NFSCP_DEPLOYMENT=${DYNAMIC_NFSCP_DEPLOYMENT-true}

NFSSP_NAME=${NFSSP_NAME-"${PV_PREFIX}nfssp"}
# NFSSP persistent storage does not work on NFS storage.
NFSSP_PERSISTENCE_ENABLED=${NFSSP_PERSISTENCE_ENABLED-false}
NFSSP_PERSISTENCE_SIZE=${NFSSP_PERSISTENCE_SIZE-"100Gi"}
# The default storageClass for GKE is standard.
NFSSP_PERSISTENCE_STORAGECLASS=${NFSSP_PERSISTENCE_STORAGECLASS-""}
NFSSP_STORAGECLASS=${NFSSP_STORAGECLASS-"$NFSSP_NAME-sc"}

NFSCP_SERVER=${NFSCP_SERVER-""}
# Currently the NFSCP_PATH directory needs to exist on the NFS server.
NFSCP_PATH=${NFSCP_PATH-""}
NFSCP_NAME=${NFSCP_NAME-"nfscp"}
NFSCP_STORAGECLASS=${NFSCP_STORAGECLASS-"$NFSCP_NAME-sc"}

if $DYNAMIC_NFSCP_DEPLOYMENT; then
  NFSP_STORAGECLASS=$NFSCP_STORAGECLASS
else
  NFSP_STORAGECLASS=$NFSSP_STORAGECLASS
fi

# GCE_DYN_STORAGE_PD_NAME="${PV_PREFIX}nfssp"
GCE_DYN_STORAGE_PD_NAME="${NFSSP_NAME}"
GCE_DYN_STORAGE_PV_NAME="${GCE_DYN_STORAGE_PD_NAME}-nfs-server-provisioner"
GCE_DYN_STORAGE_PV_STORAGE=$NFSSP_PERSISTENCE_SIZE
GCE_DYN_STORAGE_CLAIMREF="data-$GCE_DYN_STORAGE_PV_NAME-0"

ELASTIC_PVC_STORAGE=${ELASTIC_PVC_STORAGE-"10Gi"}
# Set X_STORAGECLASS to "" to use the default storage class.
ELASTIC_STORAGECLASS=${ELASTIC_STORAGECLASS-$NFSP_STORAGECLASS}
APPSTORE_DB_STORAGECLASS=${APPSTORE_DB_STORAGECLASS-$NFSP_STORAGECLASS}
COMMONSSHARE_DB_STORAGECLASS=${COMMONSSHARE_DB_STORAGECLASS-$NFSP_STORAGECLASS}

# This is temporary until we figure out something to use to encrypt secret
# files, like git-crypt.  ToDo: Also add something like this for appstore.
HYDROSHARE_SECRET_SRC_FILE=${HYDROSHARE_SECRET_SRC_FILE-"$HELXPLATFORM_HOME/hydroshare-secret.yaml"}
HYDROSHARE_SECRET_DST_FILE=${HYDROSHARE_SECRET_DST_FILE-"$CAT_HELM_DIR/charts/commonsshare/templates/hydroshare-secret.yaml"}

NFSRODS_NAME=${NFSRODS_NAME-"nfsrods"}
NFSRODS_HELM_DIR=${NFSRODS_HELM_DIR-"$K8S_DEVOPS_CORE_HOME/helx/charts/nfsrods"}
NFSRODS_PV_NAME=${NFSRODS_PV_NAME-"${PV_PREFIX}$NFSRODS_NAME-pv"}
NFSRODS_PV_STORAGE_SIZE=${NFSRODS_PV_STORAGE_SIZE-"100Gi"}
NFSRODS_PV_STORAGECLASS=${NFSRODS_PV_STORAGECLASS-"$NFSRODS_NAME-sc"}
# ToDo: Pull this IP from from the service after it's created and use that to
# create the PVC.
NFSRODS_PV_NFS_SERVER_IP=${NFSRODS_PV_NFS_SERVER_IP-"10.233.58.200"}
NFSRODS_PV_NFS_PATH=${NFSRODS_PV_NFS_PATH-"/"}
NFSRODS_PV_ACCESSMODE=${NFSRODS_PV_ACCESSMODE-"ReadWriteMany"}
NFSRODS_PVC_CLAIMNAME=${NFSRODS_PVC_CLAIMNAME-"$NFSRODS_NAME-pvc"}
NFSRODS_PVC_STORAGE_SIZE=${NFSRODS_PVC_STORAGE_SIZE-"10Gi"}
NFSRODS_FOR_USER_DATA=${NFSRODS_FOR_USER_DATA-false}
NFSRODS_CONFIG_PV_NAME=${NFSRODS_CONFIG_PV_NAME-"${PV_PREFIX}$NFSRODS_NAME-config-pv"}
NFSRODS_CONFIG_CLAIMNAME=${NFSRODS_CONFIG_CLAIMNAME-"$NFSRODS_NAME-config-pvc"}
NFSRODS_CONFIG_NFS_SERVER=${NFSRODS_CONFIG_NFS_SERVER-""}
NFSRODS_CONFIG_NFS_PATH=${NFSRODS_CONFIG_NFS_PATH-""}
NFSRODS_CONFIG_PV_STORAGECLASS=${NFSRODS_CONFIG_PV_STORAGECLASS-"$NFSRODS_NAME-config-sc"}
NFSRODS_CONFIG_PV_STORAGE_SIZE=${NFSRODS_CONFIG_PV_STORAGE_SIZE-"10Mi"}
NFSRODS_CONFIG_PV_ACCESSMODE=${NFSRODS_CONFIG_PV_ACCESSMODE-"ReadWriteMany"}

#
# end default user-definable variable definitions
#


function createGCEDisk(){
  local PD_NAME=$1
  local DISK_SIZE=$2
  gcloud compute disks create --project $PROJECT --zone=$AVAILABILITY_ZONE --size=$DISK_SIZE $PD_NAME
}


function deleteGCEDisk(){
  local PD_NAME=$1
  gcloud compute disks delete --project $PROJECT --zone $AVAILABILITY_ZONE --quiet $PD_NAME
}


function createGKEPV(){
  local PD_NAME=$1
  local PV_NAME=$2
  local PV_STORAGE=$3
  local CLAIMREF=$4
  echo -e "
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $PV_NAME
spec:
  capacity:
    storage: $PV_STORAGE
  accessModes:
    - ReadWriteOnce
  gcePersistentDisk:
    fsType: \"ext4\"
    pdName: "$PD_NAME"
  claimRef:
    namespace: $NAMESPACE
    name: $CLAIMREF
---
" | kubectl create -f -
}


createGKEPVC(){
  local PVC_NAME=$1
  local PVC_STORAGE=$2
  echo -e "
---
  apiVersion: v1
  kind: PersistentVolumeClaim
  metadata:
    name: $PVC_NAME
  spec:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: $PVC_STORAGE
---
" | kubectl -n $NAMESPACE create -f -
}


function deleteGKEPVC(){
  local PVC_NAME=$1
  kubectl -n $NAMESPACE delete pvc $PVC_NAME
}


function deleteGKEPV(){
  local PV_NAME=$1
  kubectl -n $NAMESPACE delete pv $PV_NAME
}


function deployDynamicPVCP() {
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" = true ]; then
    echo "Deploying NFS Client Provisioner for Dynamic PVCs"
    $HELM -n $NAMESPACE upgrade --install \
                 --set nfs.server=$NFSCP_SERVER \
                 --set nfs.path=$NFSCP_PATH \
                 --set storageClass.name=$NFSCP_STORAGECLASS \
                 $NFSCP_NAME stable/nfs-client-provisioner
  else
    if [ "$GKE_DEPLOYMENT" = true ]; then
      createGCEDisk $GCE_DYN_STORAGE_PD_NAME $GCE_DYN_STORAGE_PV_STORAGE
      createGKEPV $GCE_DYN_STORAGE_PD_NAME $GCE_DYN_STORAGE_PV_NAME \
          $GCE_DYN_STORAGE_PV_STORAGE $GCE_DYN_STORAGE_CLAIMREF
    fi
    echo "Deploying NFS Server Provisioner for Dynamic PVCs"
    HELM_VALUES="persistence.enabled=$NFSSP_PERSISTENCE_ENABLED"
    HELM_VALUES+=",storageClass.name=$NFSSP_STORAGECLASS"
    HELM_VALUES+=",persistence.size=$NFSSP_PERSISTENCE_SIZE"
    HELM_VALUES+=",persistence.storageClass=$NFSSP_PERSISTENCE_STORAGECLASS"
    $HELM -n $NAMESPACE upgrade --install $NFSSP_NAME \
        --set $HELM_VALUES stable/nfs-server-provisioner
  fi
}


function deleteDynamicPVCP() {
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" = true ]; then
    echo "Deleting NFS Client Provisioner for Dynamic PVCs"
    $HELM -n $NAMESPACE delete $NFSCP_NAME
  else
    echo "Deleting NFS Server Provisioner for Dynamic PVCs"
    $HELM -n $NAMESPACE delete $NFSSP_NAME
    if [ "$GKE_DEPLOYMENT" = true ]; then
      deleteGKEPV $GCE_DYN_STORAGE_PD_NAME $GCE_DYN_STORAGE_PV_NAME \
          $GCE_DYN_STORAGE_CLAIMREF
      echo "Pausing for PV to be deleted fully."
      sleep 15
      deleteGCEDisk $GCE_DYN_STORAGE_PD_NAME
    fi
  fi
}


function deployELK(){
   echo "# deploying ELK"
   export PVC_STORAGE_CLASS_NAME=$ELASTIC_STORAGECLASS
   export ELASTIC_PVC_STORAGE
   cat $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-template.yaml | envsubst | \
          kubectl apply -n $NAMESPACE -f -
   # kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch.yaml
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/es-service.yaml

   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/logstash/
   echo "# end deploying ELK"
}


function deleteELK(){
   echo "# deleting ELK"
   # delete ELK
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/es-service.yaml

   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/logstash/
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/kibana/

   # kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch.yaml
   export PVC_STORAGE_CLASS_NAME=$NFSP_STORAGECLASS
   export ELASTIC_PVC_STORAGE
   cat $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-template.yaml | envsubst | \
          kubectl delete -n $NAMESPACE -f -
   echo "# end deleting ELK"
}


function deployNFSServer(){
   echo "# deploying NFS"
   kubectl create namespace $NAMESPACE
   createGCEDisk $GCE_NFS_SERVER_DISK $GCE_NFS_SERVER_STORAGE
   export GCE_NFS_SERVER_DISK=${1-$GCE_NFS_SERVER_DISK}
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
   kubectl apply -n $NAMESPACE -R -f \
       $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc.yaml
   # createNFSServerPVPVC $NFS_CLNT_PV_NFS_PATH $NFS_CLNT_PV_NFS_SRVR \
   #     $NFS_CLNT_PV_NAME $NFS_CLNT_PVC_NAME $NFS_CLNT_STORAGECLASS
   echo "# end deploying NFS"
}


# function createNFSServerPVPVC(){
#   export PV_NFS_PATH=$1
#   export PV_NFS_SERVER=$2
#   export PV_NAME=$3
#   export PVC_NAME=$4
#   export STORAGECLASS_NAME=$5
#   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-client-pvc-pv-template.yaml | envsubst | \
#       kubectl create -n $NAMESPACE -f -
# }


function deleteNFSServer(){
   echo "# deleting NFS"
   kubectl -n $NAMESPACE delete pvc $NFS_CLNT_PVC_NAME
   kubectl -n $NAMESPACE delete pv $NFS_CLNT_PV_NAME
   export GCE_NFS_SERVER_DISK=${1-$GCE_NFS_SERVER_DISK}
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-template.yaml | envsubst | \
       kubectl delete -n $NAMESPACE -f -
   kubectl delete -n $NAMESPACE svc nfs-server
   echo "# end deleting NFS"
}


function createPVC(){
   export PVC_NAME=$1
   export PVC_STORAGE_SIZE=$2
   # PVC_STORAGE_CLASS_NAME can be empty.
   export PVC_STORAGE_CLASS_NAME=$3
   echo "# creating $PVC_NAME PVC"
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/pvc-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
   echo "# $PVC_NAME PVC created"
}


function deletePVC(){
    export PVC_NAME=$1
    export PVC_STORAGE_SIZE=$2
    # PVC_STORAGE_CLASS_NAME can be empty.
    export PVC_STORAGE_CLASS_NAME=$3
    echo "# deleting $PVC_NAME PVC"
    cat $K8S_DEVOPS_CORE_HOME/nfs-server/pvc-template.yaml | envsubst | \
        kubectl delete -n $NAMESPACE -f -
    echo "# $PVC_NAME PVC deleted"
}


function createExternalNFSPV(){
   PV_NAME=$1
   PV_NFS_SERVER=$2
   PV_NFS_PATH=$3
   PV_STORAGECLASS=$4
   PV_STORAGE_SIZE=$5
   PV_ACCESSMODE=$6
   echo "# creating $PV_NAME NFS PV"
   echo -e "
---
apiVersion: v1
kind: PersistentVolume
metadata:
 name: $PV_NAME
spec:
 capacity:
   storage: $PV_STORAGE_SIZE
 accessModes:
   - $PV_ACCESSMODE
 persistentVolumeReclaimPolicy:
   Retain
 storageClassName: $PV_STORAGECLASS
 nfs:
   path: $PV_NFS_PATH
   server: $PV_NFS_SERVER
---
" | kubectl create -n $NAMESPACE -f -
   echo "# $PV_NAME NFS PV created"
}


function createExternalNFSPVC(){
  PVC_NAME=$1
  PVC_STORAGECLASS=$2
  PVC_STORAGE_SIZE=$3
  PVC_ACCESSMODE=$4
  echo "# creating $PVC_NAME NFS PVC"
  echo -e "
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: $PVC_NAME
spec:
 accessModes:
 - $PVC_ACCESSMODE
 resources:
    requests:
      storage: $PVC_STORAGE_SIZE
 storageClassName: $PVC_STORAGECLASS
---
" | kubectl create -n $NAMESPACE -f -
   echo "# $PVC_NAME NFC PVC created"
}


function deleteExternalNFSPV(){
   PV_NAME=$1
   PV_NFS_SERVER=$2
   PV_NFS_PATH=$3
   PV_STORAGECLASS=$4
   PV_STORAGE_SIZE=$5
   PV_ACCESSMODE=$6
   echo "# deleting $PV_NAME NFS PV"
   echo -e "
---
apiVersion: v1
kind: PersistentVolume
metadata:
 name: $PV_NAME
spec:
 capacity:
   storage: $PV_STORAGE_SIZE
 accessModes:
   - $PV_ACCESS_MODE
 persistentVolumeReclaimPolicy:
   Retain
 storageClassName: $PV_STORAGECLASS
 nfs:
   path: $PV_NFS_PATH
   server: $PV_NFS_SERVER
---
" | kubectl delete -n $NAMESPACE -f -
   echo "# $PV_NAME NFS PV deleted"
}


function deleteExternalNFSPVC(){
  PVC_NAME=$1
  PVC_NFS_SERVER=$2
  PVC_NFS_PATH=$3
  PVC_STORAGECLASS=$4
  PVC_STORAGE_SIZE=$5
  PVC_ACCESSMODE=$6
  echo "# deleting $PVC_NAME NFS PVC"
  echo -e "
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: $PVC_NAME
spec:
 accessModes:
 - $PVC_ACCESSMODE
 resources:
    requests:
      storage: $PVC_STORAGE_SIZE
 storageClassName: $PVC_STORAGECLASS
---
" | kubectl delete -n $NAMESPACE -f -
   echo "# $PVC_NAME NFC PVC deleted"
}


function deployCAT(){
  echo "# deploying CAT"
  # Create PVC for CAT before deploying CAT.
  if [ "$GKE_DEPLOYMENT" = true ]; then
    # createGCEDisk $CAT_PD_NAME $CAT_DISK_SIZE
    # createGKEPV $CAT_PD_NAME $CAT_PV_NAME $CAT_PVC_STORAGE $CAT_USER_STORAGE_NAME
    createGCEDisk $APPSTORE_OAUTH_PD_NAME $APPSTORE_OAUTH_PV_STORAGE_SIZE
    createGKEPV $APPSTORE_OAUTH_PD_NAME $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PVC
    createGKEPVC $APPSTORE_OAUTH_PVC $APPSTORE_OAUTH_PV_STORAGE_SIZE
  else
    createExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
        $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
    createPVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
    createExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
        $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
        $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
  fi
  if [ -f "$HYDROSHARE_SECRET_SRC_FILE" ]
  then
   echo "copying \"$HYDROSHARE_SECRET_SRC_FILE\" to"
   echo "  \"$HYDROSHARE_SECRET_DST_FILE\""
   cp $HYDROSHARE_SECRET_SRC_FILE $HYDROSHARE_SECRET_DST_FILE
  else
   echo "Hydroshare secret source file not found:"
   echo "  file: \"$HYDROSHARE_SECRET_SRC_FILE\""
   echo "### Not copying hydroshare secret file. ###"
  fi
  HELM_VALUES="web.db.storageClass=$COMMONSSHARE_DB_STORAGECLASS"
  $HELM -n $NAMESPACE upgrade --install $COMMONSSHARE_NAME \
    $CAT_HELM_DIR/charts/commonsshare --debug --logtostderr --set $HELM_VALUES

  HELM_VALUES="db.storageClass=$APPSTORE_DB_STORAGECLASS"
  if [ ! -z "$APPSTORE_OAUTH_PVC" ]
  then
   HELM_VALUES+=",oauth.pvcname=$APPSTORE_OAUTH_PVC"
  fi
  if [ ! -z "$APPSTORE_OAUTH_PV_STORAGECLASS" ]
  then
   HELM_VALUES+=",oauth.storageClass=$APPSTORE_OAUTH_PV_STORAGECLASS"
  fi
  if [ ! -z "$APPSTORE_IMAGE" ]
  then
   HELM_VALUES+=",image=$APPSTORE_IMAGE"
  fi
  if [ ! -z "$APPSTORE_IMAGE_PULL_SECRETS" ]
  then
   HELM_VALUES+=",imagePullSecrets=$APPSTORE_IMAGE_PULL_SECRETS"
  fi
  $HELM -n $NAMESPACE upgrade --install $APPSTORE_NAME \
     $CAT_HELM_DIR/charts/appstore --debug --logtostderr --set $HELM_VALUES

  if [ "$TYCHO_USE_ROLE" = false ]
  then
   HELM_VALUES+=",useRole=false"
  fi
  if [ "$USE_CLUSTER_ROLES" = true ]
  then
    HELM_VALUES+=",useClusterRole=true"
  fi
  if [ ! -z "$TYCHO_API_SERVICE_TYPE" ]
  then
    HELM_VALUES+=",service.type=$TYCHO_API_SERVICE_TYPE"
  fi
  HELM_VALUES+=",serviceAccount.name=${PV_PREFIX}tycho-api"
  if [ ! -z "$TYCHO_API_IMAGE" ]
  then
    HELM_VALUES+=",image=$TYCHO_API_IMAGE"
  fi
  $HELM -n $NAMESPACE upgrade --install $TYCHO_NAME \
     $CAT_HELM_DIR/charts/tycho-api --debug --logtostderr --set $HELM_VALUES
   # For some reason deleting Helm chart for cat does not remove this secret
   # and upgrading Helm chart fails.
   # kubectl -n $NAMESPACE delete secret hydroshare-secret
   # kubectl -n $NAMESPACE delete configmap csappstore-env hydroshare-env
   # $HELM -n $NAMESPACE upgrade --install $CAT_USER_STORAGE_NAME $CAT_HELM_DIR --debug \
   #      --logtostderr --set $HELM_VALUES
   echo "# end deploying CAT"
}


function deleteCAT(){
  echo "# deleting CAT"
  $HELM -n $NAMESPACE delete $COMMONSSHARE_NAME
  $HELM -n $NAMESPACE delete $APPSTORE_NAME
  $HELM -n $NAMESPACE delete $TYCHO_NAME
  if [ "$GKE_DEPLOYMENT" = true ]; then
    # deleteGKEPV $CAT_PD_NAME $CAT_PV_NAME $CAT_USER_STORAGE_NAME
    # deleteGCEDisk $CAT_PD_NAME
    deleteGKEPVC $APPSTORE_OAUTH_PVC
    deleteGKEPV $APPSTORE_OAUTH_PV_NAME
    deleteGCEDisk $APPSTORE_OAUTH_PD_NAME
  else
    deletePVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
    deleteExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
      $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
    # The helm chart handles deletion of PVC.
    deleteExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
      $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
      $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
  fi
  echo "# end deleting CAT"
}


function deployAmbassador(){
   echo "# deploying Ambassador"
   if [ "$USE_CLUSTER_ROLES" = false ]; then
     HELM_VALUES="prp.deployment=true"
     HELM_SET_ARG="--set $HELM_VALUES"
   else
     HELM_SET_ARG=""
   fi
   $HELM -n $NAMESPACE upgrade --install ambassador $AMBASSADOR_HELM_DIR --debug \
       --logtostderr $HELM_SET_ARG
   echo "# end deploying Ambassador"
}


function deleteAmbassador(){
   echo "# deleting Ambassador"
   $HELM -n $NAMESPACE delete ambassador
   kubectl delete -n $NAMESPACE CustomResourceDefinition  mappings.getambassador.io
   echo "# end deleting Ambassador"
}


function deployNginx(){
   echo "# deploying Nginx"
   if [ ! -z "$NGINX_TLS_KEY" ]
   then
     # create TLS secret for nginx
     kubectl --namespace $NAMESPACE create secret generic $NGINX_TLS_SECRET \
        --from-file=tls.crt=$NGINX_TLS_CRT \
        --from-file=tls.key=$NGINX_TLS_KEY \
        --from-file=ca.crt=$NGINX_TLS_CA_CRT
   fi
   HELM_VALUES="service.serverName=$NGINX_SERVERNAME"
   HELM_VALUES+=",service.IP=$NGINX_IP"
   HELM_VALUES+=",service.type=\"$NGINX_SERVICE_TYPE\""
   if [ ! -z "$NGINX_TLS_SECRET" ]
   then
     HELM_VALUES+=",SSL.nginxTLSSecret=$NGINX_TLS_SECRET"
   fi
   if [ ! -z "$NGINX_DNS_RESOLVER" ]
   then
     HELM_VALUES+=",service.resolver=$NGINX_DNS_RESOLVER"
   fi
   if [ ! -z "$NGINX_INGRESS_HOST" ]
   then
     HELM_VALUES+=",ingress.host=$NGINX_INGRESS_HOST"
   fi
   if [ ! -z "$NGINX_INGRESS_CLASS" ]
   then
     HELM_VALUES+=",ingress.class=\"$NGINX_INGRESS_CLASS\""
   fi
   $HELM -n $NAMESPACE upgrade --install nginx-revproxy $NGINX_HELM_DIR --debug \
       --logtostderr --set $HELM_VALUES
   echo "# end deploying Nginx"
}


function deleteNginx(){
  echo "# deleting Nginx"
  $HELM -n $NAMESPACE delete nginx-revproxy
  if [ ! -z "$NGINX_TLS_KEY" ]
  then
   kubectl --namespace $NAMESPACE delete secret $NGINX_TLS_SECRET
  fi
  echo "# end deleting Nginx"
}


function deployNFSRODS(){
  echo "deploying NFSRODS"
  HELM_VALUES="config.claimName=$NFSRODS_CONFIG_CLAIMNAME"
  HELM_VALUES+=",config.storageClass=$NFSRODS_CONFIG_PV_STORAGECLASS"
  HELM_VALUES+=",service.ip=$NFSRODS_PV_NFS_SERVER_IP"
  $HELM -n $NAMESPACE upgrade --install $NFSRODS_NAME $NFSRODS_HELM_DIR --debug \
      --logtostderr --set $HELM_VALUES
  echo "NFSRODS deployed"
}


function deleteNFSRODS(){
  echo "deleting NFSRODS"
  $HELM -n $NAMESPACE delete $NFSRODS_NAME
  echo "NFSRODS deleted"
}


case $APPS_ACTION in
  deploy)
    case $APP in
      all)
        deployDynamicPVCP
        createPVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE $NFSP_STORAGECLASS
        # create disks (GKE or BM)
        # Install SSL/TLS certificates.  Reserve static IP.  Set DNS IP.
        deployELK
        deployCAT
        deployAmbassador
        deployNginx
        ;;
      ambassador)
        deployAmbassador
        ;;
      cat)
        deployCAT
        ;;
      disks)
        if [ "$GKE_DEPLOYMENT" = true ]; then
          createGCEDisk $CAT_USER_STORAGE_NAME
          createGKEPV
        else
          createExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
              $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
          createPVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
          createExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
              $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
              $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
        fi
        ;;
      gcedisks)
        createGCEDisk $CAT_USER_STORAGE_NAME
        createGKEPV
        ;;
      dynamicPVCP)
        deployDynamicPVCP
        ;;
      elk)
        deployELK
        ;;
      nextflowPVC)
        createPVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE $NFSP_STORAGECLASS
        ;;
      nfs-server)
        deployNFSServer
        # createPVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
        # createPVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE $NFSP_STORAGECLASS
        ;;
      nfsrods)
        if [ "$NFSRODS_FOR_USER_DATA" = true ]; then
          createExternalNFSPV $NFSRODS_CONFIG_PV_NAME $NFSRODS_CONFIG_NFS_SERVER \
              $NFSRODS_CONFIG_NFS_PATH $NFSRODS_CONFIG_PV_STORAGECLASS \
              $NFSRODS_CONFIG_PV_STORAGE_SIZE $NFSRODS_CONFIG_PV_ACCESSMODE
        fi
        deployNFSRODS
        createExternalNFSPV $NFSRODS_PV_NAME $NFSRODS_PV_NFS_SERVER_IP \
            $NFSRODS_PV_NFS_PATH $NFSRODS_PV_STORAGECLASS \
            $NFSRODS_PV_STORAGE_SIZE $NFSRODS_PV_ACCESSMODE
        createPVC $NFSRODS_PVC_CLAIMNAME $NFSRODS_PVC_STORAGE_SIZE $NFSRODS_PV_STORAGECLASS
        ;;
      nginx)
        deployNginx
        ;;
      staticNFSPVPVC)
        createExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
            $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
        createPVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
        createExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
            $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
            $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
        ;;
      *)
        print_apps_help
        exit 1
        ;;
    esac
    ;;
  delete)
    case $APP in
      all)
        deleteNginx
        deleteAmbassador
        deleteCAT
        deleteELK
        deletePVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE $NFSP_STORAGECLASS
        deletePVC $NFSRODS_PVC_CLAIMNAME $NFSRODS_PVC_STORAGE_SIZE $NFSRODS_PV_STORAGECLASS
        deleteExternalNFSPV $NFSRODS_PV_NAME $NFSRODS_PV_NFS_SERVER_IP \
            $NFSRODS_PV_NFS_PATH $NFSRODS_PV_STORAGECLASS \
            $NFSRODS_PV_STORAGE_SIZE $NFSRODS_PV_ACCESSMODE
        deleteNFSServer
        deleteNFSRODS
        deleteExternalNFSPV $NFSRODS_CONFIG_PV_NAME $NFSRODS_CONFIG_NFS_SERVER \
            $NFSRODS_CONFIG_NFS_PATH $NFSRODS_CONFIG_PV_STORAGECLASS \
            $NFSRODS_CONFIG_PV_STORAGE_SIZE $NFSRODS_CONFIG_PV_ACCESSMODE
        deleteDynamicPVCP
        ;;
      ambassador)
        deleteAmbassador
        ;;
      cat)
        deleteCAT
        ;;
      disks)
        if [ "$GKE_DEPLOYMENT" = true ]; then
          deleteGKEPV
          deleteGCEDisk $CAT_USER_STORAGE_NAME
        else
          deleteExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
              $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
              $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
          deletePVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
          deleteExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
              $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
        fi
        ;;
      gcedisks)
        deleteGKEPV
        deleteGCEDisk $CAT_USER_STORAGE_NAME
        ;;
      dynamicPVCP)
        deleteDynamicPVCP
        ;;
      elk)
        deleteELK
        ;;
      nextflowPVC)
        deletePVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE $NFSP_STORAGECLASS
        ;;
      nfs-server)
        # deletePVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE  $NFSP_STORAGECLASS
        # deletePVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
        deleteNFSServer
        sleep 20
        deleteGCEDisk $GCE_NFS_SERVER_DISK
        ;;
      nfsrods)
        deletePVC $NFSRODS_PVC_CLAIMNAME $NFSRODS_PVC_STORAGE_SIZE $NFSRODS_PV_STORAGECLASS
        deleteExternalNFSPV $NFSRODS_PV_NAME $NFSRODS_PV_NFS_SERVER_IP \
            $NFSRODS_PV_NFS_PATH $NFSRODS_PV_STORAGECLASS \
            $NFSRODS_PV_STORAGE_SIZE $NFSRODS_PV_ACCESSMODE
        deleteNFSRODS
        deletePVC $NFSRODS_PVC_CLAIMNAME $NFSRODS_PVC_STORAGE_SIZE $NFSRODS_PV_STORAGECLASS
        if [ "$NFSRODS_FOR_USER_DATA" = true ]; then
          deleteExternalNFSPV $NFSRODS_CONFIG_PV_NAME $NFSRODS_CONFIG_NFS_SERVER \
              $NFSRODS_CONFIG_NFS_PATH $NFSRODS_CONFIG_PV_STORAGECLASS \
              $NFSRODS_CONFIG_PV_STORAGE_SIZE $NFSRODS_CONFIG_PV_ACCESSMODE
        fi
        ;;
      nginx)
        deleteNginx
        ;;
      staticNFSPVPVC)
        deleteExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
            $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
            $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
        deletePVC $CAT_USER_STORAGE_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
        deleteExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
            $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
         ;;
      *)
        print_apps_help
        exit 1
        ;;
    esac
    ;;
  loadFunctions)
    ;;
  *)
    print_apps_help
    exit 1
    ;;
esac
