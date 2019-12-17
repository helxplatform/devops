#!/bin/bash

#
# Install base applications to Kubernetes cluster.
#

# To override the variables below you can can export them out in a file and
# then set the variable "GKE_CLUSTER_CONFIG" to the location of that file.
# Setting at least CLUSTER_NAME, e.g., "pjl-stage", would be good for developer
# testing.

if [ "$1" == "loadFunctions" ]
then
  echo "k8s-apps: Ignoring GKE_CLUSTER_CONFIG and only loading functions."
else
  if  [ -z ${GKE_CLUSTER_CONFIG+x} ]
  then
    echo "Using values from shell or defaults in this script."
  else
    echo "k8s-apps: Sourcing ${GKE_CLUSTER_CONFIG}"
    source ${GKE_CLUSTER_CONFIG}
  fi
fi

function print_apps_help() {
  echo "\
usage: $0 <action> <app>
  actions: deploy, delete
  apps: cat, elk, nfs, all
  -h|--help      Print this help message.
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
    *)
      # unknown option
      print_apps_help
      exit 1
      ;;
  esac
  shift # past argument or value
done


# set -e

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
NAMESPACE=${NAMESPACE-default}
HELIUMPLUSDATASTAGE_HOME=${HELIUMPLUSDATASTAGE_HOME-"../.."}
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-"${HELIUMPLUSDATASTAGE_HOME}/heliumplus-k8s-devops-core"}
GKE_DEPLOYMENT=${GKE_DEPLOYMENT-true}

NFS_SERVER=${NFS_SERVER-"nfs.testserver.org"}
NFS_PATH=${NFS_PATH-"/some/shared/nfs/folder"}
NFSCP_NAME=${NFSCP_NAME-"elk-nfscp"}
ELK_STORAGE_CLASS_NAME=${ELK_STORAGE_CLASS_NAME-"elk-sc"}
ELK_PVC_NAME=${ELK_PVC_NAME-"elk-pvc"}
ELK_PVC_STORAGE_SIZE=${ELK_PVC_STORAGE_SIZE-"10Gi"}

NFS_CLNT_PV_NFS_PATH=${NFS_CLNT_PV_NFS_PATH-"/"}
# for GKE deployment use...
NFS_CLNT_PV_NFS_SRVR=${NFS_CLNT_PV_NFS_SRVR-"nfs-server.default.svc.cluster.local"}
NFS_CLNT_SVC_CLSTRIP_DEC=${NFS_CLNT_SVC_CLSTRIP_DEC-""}
# for local bare-metal kubernetes deployment use something like this in your
# variables file...
# export NFS_CLNT_PV_NFS_SRVR="10.233.58.201"
# export NFS_CLNT_SVC_CLSTRIP_DEC="clusterIP: 10.233.58.201"
NFS_CLNT_PV_NAME=${NFS_CLNT_PV_NAME-"nfs-client-pv"}
NFS_CLNT_PVC_NAME=${NFS_CLNT_PVC_NAME-"nfs-client-pvc"}
NFS_CLNT_STORAGECLASS=${NFS_CLNT_STORAGECLASS-"nfs-client-sc"}

HELM=${HELM-helm}
CAT_HELM_DIR=${CAT_HELM_DIR-"${HELIUMPLUSDATASTAGE_HOME}/CAT_helm"}
CAT_NAME=${CAT_NAME-cat}

# This is temporary until we figure out something to use to encrypt secret
# files, like git-crypt.
HYDROSHARE_SECRET_SRC_FILE=${HYDROSHARE_SECRET_SRC_FILE-"$HELIUMPLUSDATASTAGE_HOME/hydroshare-secret.yaml"}
HYDROSHARE_SECRET_DST_FILE=${HYDROSHARE_SECRET_DST_FILE-"$CAT_HELM_DIR/charts/commonsshare/templates/hydroshare-secret.yaml"}

#
# end default user-definable variable definitions
#

function deployELK(){
   echo "deploying ELK"
   # deploy ELK
   if $GKE_DEPLOYMENT; then
     # setup persistent storage for GKE
     kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage-gke.yaml
   else
     # setup persistent storage for bare-metal k8s
     $HELM install --name $NFSCP_NAME \
                  --set nfs.server=$NFS_SERVER \
                  --set nfs.path=$NFS_PATH \
                  --set storageClass.name=$ELK_STORAGE_CLASS_NAME \
                  --namespace $NAMESPACE \
                  stable/nfs-client-provisioner
     # used for ELK storage template
     export PVC_NAME=$ELK_PVC_NAME
     export PVC_STORAGE_CLASS_NAME=$ELK_STORAGE_CLASS_NAME
     export PVC_STORAGE_REQUESTED=$ELK_PVC_STORAGE_SIZE
     cat $K8S_DEVOPS_CORE_HOME/elasticsearch/pvc-template.yaml | envsubst | \
         kubectl create -n $NAMESPACE -f -
     kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage.yaml
     # kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage.yaml
   fi

   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch.yaml
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/es-service.yaml

   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/logstash/
}

function deleteELK(){
   echo "deleting ELK"
   # delete ELK
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/es-service.yaml
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch.yaml
   if $GKE_DEPLOYMENT; then
     # delete persistent storage for GKE
     kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage-gke.yaml
   else
     # delete persistent storage for bare-metal k8s
     kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage.yaml
     # used for ELK storage template
     export PVC_NAME=$ELK_PVC_NAME
     export PVC_STORAGE_CLASS_NAME=$ELK_STORAGE_CLASS_NAME
     export PVC_STORAGE_REQUESTED=$ELK_PVC_STORAGE_SIZE
     cat $K8S_DEVOPS_CORE_HOME/elasticsearch/pvc-template.yaml | envsubst | \
         kubectl delete -n $NAMESPACE -f -
     $HELM delete --namespace $NAMESPACE --purge $NFSCP_NAME
   fi

   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/logstash/

}

function deployNFS(){
   # An NFS server is deployed within the cluster since GKE does not support
   # a PV that is ReadWriteMany.
   echo "deploying NFS"
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-pvc.yaml
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server.yaml
   export PV_NFS_PATH=$NFS_CLNT_PV_NFS_PATH
   export PV_NFS_SERVER=$NFS_CLNT_PV_NFS_SRVR
   export SVC_CLSTRIP_DEC=$NFS_CLNT_SVC_CLSTRIP_DEC
   export PV_NAME=$NFS_CLNT_PV_NAME
   export PVC_NAME=$NFS_CLNT_PVC_NAME
   export STORAGECLASS_NAME=$NFS_CLNT_STORAGECLASS
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
   # deploy NFS PVC for NFS clients
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-client-pvc-pv-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
}

function deleteNFS(){
   echo "deleting NFS"
   # delete NFS server
   export PV_NFS_PATH=$NFS_CLNT_PV_NFS_PATH
   export PV_NFS_SERVER=$NFS_CLNT_PV_NFS_SRVR
   export SVC_CLSTRIP_DEC=$NFS_CLNT_SVC_CLSTRIP_DEC
   export PV_NAME=$NFS_CLNT_PV_NAME
   export PVC_NAME=$NFS_CLNT_PVC_NAME
   export STORAGECLASS_NAME=$NFS_CLNT_STORAGECLASS
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-client-pvc-pv-template.yaml | envsubst | \
       kubectl delete -n $NAMESPACE -f -
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc-template.yaml | envsubst | \
       kubectl delete -n $NAMESPACE -f -
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server.yaml
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-pvc.yaml
}

function deployCAT(){
   if [ -f "$HYDROSHARE_SECRET_SRC_FILE" ]
   then
     echo "copying \"$HYDROSHARE_SECRET_SRC_FILE\" to"
    echo "  \"$HYDROSHARE_SECRET_DST_FILE\""
     cp $HYDROSHARE_SECRET_SRC_FILE $HYDROSHARE_SECRET_DST_FILE
   else
     echo "### Not copying hydroshare secret file. ###"
   fi
   echo "executing $HELM install $CAT_NAME $CAT_HELM_DIR -n $NAMESPACE"
   $HELM install $CAT_NAME $CAT_HELM_DIR -n $NAMESPACE
}

function deleteCAT(){
   echo "executing $HELM delete $CAT_NAME"
   $HELM delete $CAT_NAME
}

case $APPS_ACTION in
  deploy)
    case $APP in
      all)
        deployNFS
        deployELK
        # pause to allow for previous deployments
        POST_ELK_WAIT="30"
        echo "Waiting $POST_ELK_WAIT seconds for deployments to happen."
        sleep $POST_ELK_WAIT
        deployCAT
        ;;
      cat)
        deployCAT
        ;;
      elk)
        deployELK
        ;;
      nfs)
        deployNFS
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
        deleteNFS
        ;;
      cat)
        deleteCAT
        ;;
      elk)
        deleteELK
        ;;
      nfs)
        deleteNFS
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
