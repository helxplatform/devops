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
HELIUMPLUSDATASTAGE_HOME=${HELIUMPLUSDATASTAGE_HOME-"../.."}
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-"${HELIUMPLUSDATASTAGE_HOME}/devops"}
GKE_DEPLOYMENT=${GKE_DEPLOYMENT-true}

GCE_PERSISTENT_DISK=${GCE_PERSISTENT_DISK-"nfs-cloud-top"}
NFS_CLNT_PV_NFS_PATH=${NFS_CLNT_PV_NFS_PATH-"/exports"}
NFS_CLNT_PV_NFS_SRVR=${NFS_CLNT_PV_NFS_SRVR-"nfs-server.default.svc.cluster.local"}
NFS_CLNT_PV_NAME=${NFS_CLNT_PV_NAME-"cloud-top-pv"}
NFS_CLNT_PVC_NAME=${NFS_CLNT_PVC_NAME-"cloud-top"}
NFS_CLNT_STORAGECLASS=${NFS_CLNT_STORAGECLASS-"cat-sc"}

HELM=${HELM-helm}
CAT_HELM_DIR=${CAT_HELM_DIR-"${HELIUMPLUSDATASTAGE_HOME}/CAT_helm"}
CAT_NAME=${CAT_NAME-cat}
CAT_PVC_NAME=${CAT_PVC_NAME-"cloud-top"}
CAT_PVC_STORAGE=${CAT_PVC_STORAGE-"1Gi"}

AMBASSADOR_HELM_DIR=${AMBASSADOR_HELM_DIR-"$K8S_DEVOPS_CORE_HOME/charts/ambassador"}
NGINX_HELM_DIR=${NGINX_HELM_DIR="$K8S_DEVOPS_CORE_HOME/charts/nginx"}
NGINX_SERVERNAME=${NGINX_SERVERNAME-"helx.helx-dev.renci.org"}
NGINX_IP=${NGINX_IP-""}
NGINX_TLS_SECRET=${NGINX_TLS_SECRET-""}

# Set DYNAMIC_NFSCP_DEPLOYMENT to false if NFS storage is not available (GKE).
DYNAMIC_NFSCP_DEPLOYMENT=${DYNAMIC_NFSCP_DEPLOYMENT-true}

NFSSP_NAME=${NFSSP_NAME-"$CAT_NAME-nfssp"}
# NFSSP persistent storage does not work on NFS storage.
NFSSP_PERSISTENCE_ENABLED=${NFSSP_PERSISTENCE_ENABLED-false}
NFSSP_PERSISTENCE_SIZE=${NFSSP_PERSISTENCE_SIZE-"10Gi"}
# The default storageClass for GKE is standard.
NFSSP_PERSISTENCE_STORAGECLASS=${NFSSP_PERSISTENCE_STORAGECLASS-""}
NFSSP_STORAGECLASS=${NFSSP_STORAGECLASS-"$CAT_NAME-sc"}

NFSCP_NAME=${NFSCP_NAME-"$CAT_NAME-nfscp"}
NFSCP_STORAGECLASS=${NFSCP_STORAGECLASS-"$CAT_NAME-sc"}

if $DYNAMIC_NFSCP_DEPLOYMENT; then
  NFSP_STORAGECLASS=$NFSCP_STORAGECLASS
else
  NFSP_STORAGECLASS=$NFSSP_STORAGECLASS
fi

ELASTIC_PVC_STORAGE=${ELASTIC_PVC_STORAGE-"1Gi"}
# Set X_STORAGECLASS to "" to use the default storage class.
ELASTIC_STORAGECLASS=${ELASTIC_STORAGECLASS-$NFSP_STORAGECLASS}
APPSTORE_DB_STORAGECLASS=${APPSTORE_DB_STORAGECLASS-$NFSP_STORAGECLASS}
COMMONSSHARE_DB_STORAGECLASS=${COMMONSSHARE_DB_STORAGECLASS-$NFSP_STORAGECLASS}

# This is temporary until we figure out something to use to encrypt secret
# files, like git-crypt.
HYDROSHARE_SECRET_SRC_FILE=${HYDROSHARE_SECRET_SRC_FILE-"$HELIUMPLUSDATASTAGE_HOME/hydroshare-secret.yaml"}
HYDROSHARE_SECRET_DST_FILE=${HYDROSHARE_SECRET_DST_FILE-"$CAT_HELM_DIR/charts/commonsshare/templates/hydroshare-secret.yaml"}

#
# end default user-definable variable definitions
#


function deployDynamicPVCP() {
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" = true ]; then
    echo "Deploying NFS Client Provisioner for Dynamic PVCs"
    $HELM install \
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
    $HELM install $NFSSP_NAME -n $NAMESPACE --set $HELM_VALUES stable/nfs-server-provisioner
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
   export GCE_PERSISTENT_DISK
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
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc.yaml
   export SVC_CLSTRIP_DEC=$NFS_SERVICE_IP
   # cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc-template.yaml | envsubst | \
   #     kubectl delete -n $NAMESPACE -f -
   export GCE_PERSISTENT_DISK
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-template.yaml | envsubst | \
       kubectl delete -n $NAMESPACE -f -
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
   createPVC $CAT_PVC_NAME $CAT_PVC_STORAGE $NFSP_STORAGECLASS
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
   CAT_HELM_VALUES="appstore.db.storageClass=\"$APPSTORE_DB_STORAGECLASS\""
   CAT_HELM_VALUES+=",commonsshare.web.db.storageClass=\"$COMMONSSHARE_DB_STORAGECLASS\""
   $HELM install $CAT_NAME $CAT_HELM_DIR -n $NAMESPACE --debug --logtostderr \
       --set $CAT_HELM_VALUES
   echo "# end deploying CAT"
}


function deleteCAT(){
  echo "# deleting CAT"
   echo "executing $HELM delete $CAT_NAME"
   $HELM delete $CAT_NAME
   deletePVC $CAT_PVC_NAME $CAT_PVC_STORAGE $NFSP_STORAGECLASS
   echo "# end deleting CAT"
}


function deployAmbassador(){
   echo "# deploying Ambassador"
   $HELM install ambassador $AMBASSADOR_HELM_DIR -n $NAMESPACE --debug \
       --logtostderr
   echo "# end deploying Ambassador"
}


function deleteAmbassador(){
   echo "# deleting CAT"
   $HELM delete ambassador
   echo "# end deleting Ambassador"
}


function deployNginx(){
   echo "# deploying Nginx"
   HELM_VALUES="service.serverName=$NGINX_SERVERNAME"
   HELM_VALUES+=",service.IP=$NGINX_IP"
   if [ ! -z "$NGINX_TLS_SECRET" ]
   then
     HELM_VALUES+=",SSL.nginxTLSSecret=$NGINX_TLS_SECRET"
   fi
   $HELM install nginx-revproxy $NGINX_HELM_DIR -n $NAMESPACE --debug \
       --logtostderr --set $HELM_VALUES
   echo "# end deploying Nginx"
}


function deleteNginx(){
   echo "# deleting Nginx"
   $HELM delete nginx-revproxy
   echo "# end deleting Nginx"
}

function createGCEDisk(){
  PV_NAME="cat-nfssp-nfs-server-provisioner"
  PV_STORAGE="10Gi"
  DISK_SIZE="10GB"
  PD_NAME="nfssp-helx-dev-cat"
  NAMESPACE="default"
  CLAIMREF="data-cat-nfssp-nfs-server-provisioner-0"
  AVAILABILITY_ZONE="us-east1-b"
  gcloud compute disks create --size=$DISK_SIZE --zone=$AVAILABILITY_ZONE $PD_NAME
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


function deleteGCEDisk(){
  PV_NAME="cat-nfssp-nfs-server-provisioner"
  PV_STORAGE="10Gi"
  DISK_SIZE="10GB"
  PD_NAME="nfssp-helx-dev-cat"
  NAMESPACE="default"
  CLAIMREF="data-cat-nfssp-nfs-server-provisioner-0"
  AVAILABILITY_ZONE="us-east1-b"
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
  gcloud compute disks delete $PD_NAME --zone $AVAILABILITY_ZONE
}


case $APPS_ACTION in
  deploy)
    case $APP in
      all)
        deployDynamicPVCP
        # createPVC "deepgtex-prp" "5Gi" $NFSP_STORAGECLASS
        deployELK
        deployCAT
        ;;
      ambassador)
        deployAmbassador
        ;;
      cat)
        deployCAT
        ;;
      gcedisk)
        createGCEDisk
        ;;
      dynamicPVC)
        deployDynamicPVCP
        ;;
      elk)
        deployELK
        ;;
      nfs)
        deployNFS
        # createPVC "deepgtex-prp" "5Gi" $NFSP_STORAGECLASS
        ;;
      nginx)
        deployNginx
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
        deleteCAT
        deleteELK
        # deletePVC "deepgtex-prp" "5Gi" $NFSP_STORAGECLASS
        deleteNFS
        deleteDynamicPVCP
        ;;
      ambassador)
        deleteAmbassador
        ;;
      cat)
        deleteCAT
        ;;
      gcedisk)
        deleteGCEDisk
        ;;
      dynamicPVC)
        deleteDynamicPVCP
        ;;
      elk)
        deleteELK
        ;;
      nfs)
        # deletePVC "deepgtex-prp" "5Gi"  $NFSP_STORAGECLASS
        deleteNFS
        ;;
      nginx)
        deleteNginx
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
