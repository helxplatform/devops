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
ENVIRONMENT=${ENVIRONMENT-"dev"}
PV_PREFIX=${PV_PREFIX-"$ENVIRONMENT-$USER-"}
HELXPLATFORM_HOME=${HELXPLATFORM_HOME-"../.."}
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-"${HELXPLATFORM_HOME}/devops"}
GKE_DEPLOYMENT=${GKE_DEPLOYMENT-false}

GCE_PERSISTENT_DISK=${GCE_PERSISTENT_DISK-"${PV_PREFIX}nfs-cloud-top"}
NFS_CLNT_PV_NFS_PATH=${NFS_CLNT_PV_NFS_PATH-"/exports"}
NFS_CLNT_PV_NFS_SRVR=${NFS_CLNT_PV_NFS_SRVR-"nfs-server.default.svc.cluster.local"}
NFS_CLNT_PV_NAME=${NFS_CLNT_PV_NAME-"${PV_PREFIX}cloud-top-pv"}
NFS_CLNT_PVC_NAME=${NFS_CLNT_PVC_NAME-"cloud-top"}
NFS_CLNT_STORAGECLASS=${NFS_CLNT_STORAGECLASS-"cat-sc"}

NEXTFLOW_PVC=${NEXTFLOW_PVC-"deepgtex-prp"}
NEXTFLOW_STORAGE_SIZE=${NEXTFLOW_STORAGE_SIZE-"5Gi"}

AMBASSADOR_HELM_DIR=${AMBASSADOR_HELM_DIR-"$K8S_DEVOPS_CORE_HOME/charts/ambassador"}
PRP_DEPLOYMENT=${PRP_DEPLOYMENT-false}
NGINX_HELM_DIR=${NGINX_HELM_DIR="$K8S_DEVOPS_CORE_HOME/charts/nginx"}
NGINX_SERVERNAME=${NGINX_SERVERNAME-"helx.helx-dev.renci.org"}
NGINX_IP=${NGINX_IP-""}
NGINX_TLS_SECRET=${NGINX_TLS_SECRET-""}
NGINX_TLS_KEY=${NGINX_TLS_KEY-""}
NGINX_TLS_CRT=${NGINX_TLS_CRT-""}
NGINX_TLS_CA_CRT=${NGINX_TLS_CA_CRT-""}
NGINX_DNS_RESOLVER=${NGINX_DNS_RESOLVER-""}
NGINX_SERVICE_TYPE=${NGINX_SERVICE_TYPE-"LoadBalancer"}

HELM=${HELM-helm}
CAT_HELM_DIR=${CAT_HELM_DIR-"${HELXPLATFORM_HOME}/CAT_helm"}
CAT_NAME=${CAT_NAME-"cloud-top"}
CAT_PVC_NAME=${CAT_PVC_NAME-$CAT_NAME}
CAT_PVC_STORAGE=${CAT_PVC_STORAGE-"10Gi"}

CAT_PV_NAME=${CAT_PV_NAME-"${PV_PREFIX}$CAT_NAME-pv"}
CAT_NFS_SERVER=${CAT_NFS_SERVER-""}
CAT_NFS_PATH=${CAT_NFS_PATH-""}
CAT_PV_STORAGECLASS=${CAT_PV_STORAGECLASS-"$CAT_NAME-sc"}
CAT_PV_STORAGE_SIZE=${CAT_PV_STORAGE_SIZE-"10Gi"}
CAT_DISK_SIZE=${CAT_DISK_SIZE-"10GB"}
CAT_PV_ACCESSMODE=${CAT_PV_ACCESSMODE-"ReadWriteMany"}

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
TYCHO_API_SERVICE_TYPE=${TYCHO_API_SERVICE_TYPE-"LoadBalancer"}

# Set DYNAMIC_NFSCP_DEPLOYMENT to false if NFS storage is not available (GKE).
DYNAMIC_NFSCP_DEPLOYMENT=${DYNAMIC_NFSCP_DEPLOYMENT-true}

NFSSP_NAME=${NFSSP_NAME-"nfssp"}
# NFSSP persistent storage does not work on NFS storage.
NFSSP_PERSISTENCE_ENABLED=${NFSSP_PERSISTENCE_ENABLED-false}
NFSSP_PERSISTENCE_SIZE=${NFSSP_PERSISTENCE_SIZE-"10Gi"}
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

ELASTIC_PVC_STORAGE=${ELASTIC_PVC_STORAGE-"10Gi"}
# Set X_STORAGECLASS to "" to use the default storage class.
ELASTIC_STORAGECLASS=${ELASTIC_STORAGECLASS-$NFSP_STORAGECLASS}
APPSTORE_DB_STORAGECLASS=${APPSTORE_DB_STORAGECLASS-$NFSP_STORAGECLASS}
COMMONSSHARE_DB_STORAGECLASS=${COMMONSSHARE_DB_STORAGECLASS-$NFSP_STORAGECLASS}

# This is temporary until we figure out something to use to encrypt secret
# files, like git-crypt.
HYDROSHARE_SECRET_SRC_FILE=${HYDROSHARE_SECRET_SRC_FILE-"$HELXPLATFORM_HOME/hydroshare-secret.yaml"}
HYDROSHARE_SECRET_DST_FILE=${HYDROSHARE_SECRET_DST_FILE-"$CAT_HELM_DIR/charts/commonsshare/templates/hydroshare-secret.yaml"}

NFSRODS_HOME=${NFSRODS_HOME-"$K8S_DEVOPS_CORE_HOME/nfsrods"}

#
# end default user-definable variable definitions
#


function deployDynamicPVCP() {
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" = true ]; then
    echo "Deploying NFS Client Provisioner for Dynamic PVCs"
    $HELM upgrade --install \
                 --set nfs.server=$NFSCP_SERVER \
                 --set nfs.path=$NFSCP_PATH \
                 --set storageClass.name=$NFSCP_STORAGECLASS \
                 --namespace $NAMESPACE \
                 $NFSCP_NAME stable/nfs-client-provisioner
  else
    echo "Deploying NFS Server Provisioner for Dynamic PVCs"
    HELM_VALUES="persistence.enabled=$NFSSP_PERSISTENCE_ENABLED"
    HELM_VALUES+=",storageClass.name=$NFSSP_STORAGECLASS"
    HELM_VALUES+=",persistence.size=$NFSSP_PERSISTENCE_SIZE"
    HELM_VALUES+=",persistence.storageClass=$NFSSP_PERSISTENCE_STORAGECLASS"
    $HELM upgrade --install $NFSSP_NAME -n $NAMESPACE --set $HELM_VALUES stable/nfs-server-provisioner
  fi
}


function deleteDynamicPVCP() {
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" = true ]; then
    echo "Deleting NFS Client Provisioner for Dynamic PVCs"
    $HELM delete $NFSCP_NAME
  else
    echo "Deleting NFS Server Provisioner for Dynamic PVCs"
    $HELM delete $NFSSP_NAME
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


function deployNFS(){
   echo "# deploying NFS"
   # These will create storage using the default storage class.
   # kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-pvc.yaml
   # kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server.yaml
   export GCE_PERSISTENT_DISK=${1-$GCE_PERSISTENT_DISK}
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc.yaml
   export SVC_CLSTRIP_DEC=$NFS_SERVICE_IP
   # cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc-template.yaml | envsubst | \
   #     kubectl create -n $NAMESPACE -f -
   # Create PV and PVC for cloud-top
   export PV_NFS_PATH=$NFS_CLNT_PV_NFS_PATH
   export PV_NFS_SERVER=$NFS_CLNT_PV_NFS_SRVR
   export PV_NAME=$NFS_CLNT_PV_NAME
   export PVC_NAME=$NFS_CLNT_PVC_NAME
   export SVC_CLSTRIP_DEC=$NFS_SERVICE_IP
   export STORAGECLASS_NAME=$NFS_CLNT_STORAGECLASS
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-client-pvc-pv-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
   echo "# end deploying NFS"
}


function deleteNFS(){
   echo "# deleting NFS"
   # delete NFS server
   export PV_NFS_PATH=$NFS_CLNT_PV_NFS_PATH
   export PV_NFS_SERVER=$NFS_CLNT_PV_NFS_SRVR
   export PV_NAME=$NFS_CLNT_PV_NAME
   export PVC_NAME=$NFS_CLNT_PVC_NAME
   export STORAGECLASS_NAME=$NFS_CLNT_STORAGECLASS
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-client-pvc-pv-template.yaml | envsubst | \
       kubectl delete -n $NAMESPACE -f -
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc.yaml
   export SVC_CLSTRIP_DEC=$NFS_SERVICE_IP
   # cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc-template.yaml | envsubst | \
   #     kubectl delete -n $NAMESPACE -f -
   export GCE_PERSISTENT_DISK=${1-$GCE_PERSISTENT_DISK}
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-template.yaml | envsubst | \
       kubectl delete -n $NAMESPACE -f -
   kubectl delete -n $NAMESPACE svc nfs-server
   # kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server.yaml
   # kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-pvc.yaml
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
   # if [ "$GKE_DEPLOYMENT" = true ]; then
   #   createGCEDisk $CAT_PVC_NAME $CAT_DISK_SIZE $AVAILABILITY_ZONE
   #   createGCEPV
   # else
   #   # The shared directories on the NFS server need to exist.
   #   createExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
   #       $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
   # fi
   # createPVC $CAT_PVC_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
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
   HELM_VALUES="appstore.db.storageClass=$APPSTORE_DB_STORAGECLASS"
   HELM_VALUES+=",commonsshare.web.db.storageClass=$COMMONSSHARE_DB_STORAGECLASS"
   HELM_VALUES+=",tycho-api.service.type=$TYCHO_API_SERVICE_TYPE"
   HELM_VALUES+=",tycho-api.serviceAccount.name=${PV_PREFIX}tycho-api"
   if [ ! -z "$APPSTORE_OAUTH_PVC" ]
   then
     HELM_VALUES+=",appstore.oauth.pvcname=$APPSTORE_OAUTH_PVC"
   fi
   if [ ! -z "$APPSTORE_OAUTH_PV_STORAGECLASS" ]
   then
     HELM_VALUES+=",appstore.oauth.storageClass=$APPSTORE_OAUTH_PV_STORAGECLASS"
   fi
   if [ ! -z "$APPSTORE_IMAGE" ]
   then
     HELM_VALUES+=",appstore.image=$APPSTORE_IMAGE"
   fi
   if [ ! -z "$APPSTORE_IMAGE_PULL_SECRETS" ]
   then
     HELM_VALUES+=",appstore.imagePullSecrets=$APPSTORE_IMAGE_PULL_SECRETS"
  fi
  if [ "$PRP_DEPLOYMENT" = true ]; then
    HELM_VALUES+=",tycho-api.prp.deployment=True"
  fi
   # For some reason deleting Helm chart for cat does not remove this secret
   # and upgrading Helm chart fails.
   # kubectl -n $NAMESPACE delete secret hydroshare-secret
   # kubectl -n $NAMESPACE delete configmap csappstore-env hydroshare-env
   $HELM upgrade --install $CAT_NAME $CAT_HELM_DIR -n $NAMESPACE --debug --logtostderr \
       --set $HELM_VALUES
   echo "# end deploying CAT"
}


function deleteCAT(){
  echo "# deleting CAT"
  $HELM -n $NAMESPACE delete $CAT_NAME
  # if [ "$GKE_DEPLOYMENT" = true ]; then
  #   deleteGCEPV
  #   deleteGCEDisk $CAT_PVC_NAME
  # else
  #   deleteExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
  #     $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
  # fi
  # deletePVC $CAT_PVC_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
  echo "# end deleting CAT"
}


function deployAmbassador(){
   echo "# deploying Ambassador"
   if [ "$PRP_DEPLOYMENT" = true ]; then
     HELM_VALUES="prp.deployment=True"
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
   $HELM upgrade --install nginx-revproxy $NGINX_HELM_DIR -n $NAMESPACE --debug \
       --logtostderr --set $HELM_VALUES
   echo "# end deploying Nginx"
}


function deleteNginx(){
  echo "# deleting Nginx"
  $HELM delete nginx-revproxy
  if [ ! -z "$NGINX_TLS_KEY" ]
  then
   kubectl --namespace $NAMESPACE delete secret $NGINX_TLS_SECRET
  fi
  echo "# end deleting Nginx"
}


function createGCEDisk(){
  PD_NAME=${1-"nfssp-helx-dev-cat"}
  DISK_SIZE=${2-"10GB"}
  AVAILABILITY_ZONE=${3-"us-east1-b"}
  gcloud compute disks create --project $PROJECT --size=$DISK_SIZE --zone=$AVAILABILITY_ZONE $PD_NAME
}


function deleteGCEDisk(){
  PD_NAME=${1-"nfssp-helx-dev-cat"}
  AVAILABILITY_ZONE=${2-"us-east1-b"}
  gcloud compute disks delete $PD_NAME --project $PROJECT --zone $AVAILABILITY_ZONE --quiet
}


function createGCEPV(){
  PD_NAME=${1-"nfssp-helx-dev-cat"}
  PV_NAME=${2-"cat-nfssp-nfs-server-provisioner"}
  PV_STORAGE=${3-"10Gi"}
  DISK_SIZE=${4-"10GB"}
  CLAIMREF=${5-"data-$PV_NAME-0"}
  AVAILABILITY_ZONE=${6-"us-east1-b"}
  NAMESPACE=${7-"default"}
  # createGCEDisk $PD_NAME $DISK_SIZE $AVAILABILITY_ZONE
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


function deleteGCEPV(){
  PD_NAME=${1-"nfssp-helx-dev-cat"}
  PV_NAME=${2-"cat-nfssp-nfs-server-provisioner"}
  PV_STORAGE=${3-"10Gi"}
  DISK_SIZE=${4-"10GB"}
  CLAIMREF=${5-"data-$PV_NAME-0"}
  AVAILABILITY_ZONE=${6-"us-east1-b"}
  NAMESPACE=${7-"default"}
  kubectl delete pvc $CLAIMREF
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
" | kubectl delete -f -
  deleteGCEDisk $PD_NAME $AVAILABILITY_ZONE
}


function deployNFSRODS(){
  echo "deploying NFSRODS"
  # Create directory on NFS server to hold NFSRODS configuration files.
  kubectl -n $NAMESPACE create -f $NFSRODS_HOME/nfsrods-config-pv-pvc.yaml
  # Copy configuration files to NFS dir.

  # Create PV/PVC to point to NFSRODS config.
  # Deploy NFSRODS.
  kubectl -n $NAMESPACE apply -f $NFSRODS_HOME/nfsrods-deployment.yaml
  # Create cloud-top PVC to point to NFSRODS NFS share.
  kubectl -n $NAMESPACE apply -f $NFSRODS_HOME/cloud-top-pv-pvc-nfsrods.yaml
  echo "NFSRODS deployed"
}


function deleteNFSRODS(){
  echo "deleting NFSRODS"
  # Delete cloud-top PV/PVC (keep data).
  kubectl -n $NAMESPACE delete -f $NFSRODS_HOME/cloud-top-pv-pvc-nfsrods.yaml
  # Delete NFSRODS deployment.
  kubectl -n $NAMESPACE delete -f $NFSRODS_HOME/nfsrods-deployment.yaml
  kubectl -n $NAMESPACE delete -f $NFSRODS_HOME/nfsrods-config-pv-pvc.yaml
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
          createGCEDisk $CAT_PVC_NAME
          createGCEPV
        else
          createExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
              $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
        fi
        ;;
      gcedisks)
        createGCEDisk $CAT_PVC_NAME
        createGCEPV
        ;;
      dynamicPVC)
        deployDynamicPVCP
        ;;
      elk)
        deployELK
        ;;
      nfs-server)
        createGCEDisk $GCE_PERSISTENT_DISK
        deployNFS
        createPVC $CAT_PVC_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
        createPVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE $NFSP_STORAGECLASS
        ;;
      nfsrods)
        deployNFSRODS
        ;;
      nginx)
        deployNginx
        ;;
      staticNFSPVPVC)
        createExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
            $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
        createPVC $CAT_PVC_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
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
        deleteNFS
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
          deleteGCEPV
          deleteGCEDisk $CAT_PVC_NAME
        else
          deleteExternalNFSPV $CAT_PV_NAME $CAT_NFS_SERVER $CAT_NFS_PATH \
              $CAT_PV_STORAGECLASS $CAT_PV_STORAGE_SIZE $CAT_PV_ACCESSMODE
        fi
        ;;
      gcedisks)
        deleteGCEPV
        deleteGCEDisk $CAT_PVC_NAME
        ;;
      dynamicPVC)
        deleteDynamicPVCP
        ;;
      elk)
        deleteELK
        ;;
      nfs-server)
        deletePVC $NEXTFLOW_PVC $NEXTFLOW_STORAGE_SIZE  $NFSP_STORAGECLASS
        deletePVC $CAT_PVC_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
        deleteNFS
        deleteGCEDisk $GCE_PERSISTENT_DISK
        ;;
      nfsrods)
        deleteNFSRODS
        ;;
      nginx)
        deleteNginx
        ;;
      staticNFSPVPVC)
        deleteExternalNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
            $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
            $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
        deletePVC $CAT_PVC_NAME $CAT_PVC_STORAGE $CAT_PV_STORAGECLASS
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
