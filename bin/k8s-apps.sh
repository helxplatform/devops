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

NFS_SERVER=${NFS_SERVER-"nfs.testserver.org"}
NFS_PATH=${NFS_PATH-"/some/shared/nfs/folder"}
NFSCP_NAME=${NFSCP_NAME-"elk-nfscp"}
ELK_STORAGE_CLASS_NAME=${ELK_STORAGE_CLASS_NAME-"elk-sc"}
# "elk-pvc" is set staticly in "elasticsearch-storage-gke.yaml"
ELK_PVC_NAME=${ELK_PVC_NAME-"elk-pvc"}
ELK_PVC_STORAGE_SIZE=${ELK_PVC_STORAGE_SIZE-"10Gi"}

NFS_PROVISIONER_NAME=${NFS_PROVISIONER_NAME-"nfs"}
NFS_PROVISIONER_PERSISTENCE_ENABLED=${NFS_PROVISIONER_PERSISTENCE_ENABLED-"false"}
NFS_PROVISIONER_PERSISTENCE_SIZE=${NFS_PROVISIONER_PERSISTENCE_SIZE-"10Gi"}

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

# ToDo:  Deploy the NFS server provisioner first, if needed and use it's storage
# for ELK, ImageJ, and Nextflow.  Then remove or adjust PVC for ELK below.
# Maybe use the NFS server provisioner everywhere?  It's probably good to have
# the option of not using the NFS server provisioner where we don't have to (not
# on Google).

function deployELK(){
   echo "# deploying ELK"

   # # Creating storage.
   # if $GKE_DEPLOYMENT; then
   #   echo "Deploying storage for GKE."
   #   # setup persistent storage for GKE
   #   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage-gke.yaml
   # else
   #   echo "Deploying storage for non-GKE environments."
   #   # This will work, but might want to use a static NFS PV instead or just
   #   # use the default storage class.
   #   # setup persistent storage for bare-metal k8s
   #   # Another note: Does this need to be ELK-specific?  Maybe there should be
   #   # a NFSCP for different storage types, like SSD, magnetic drives, data to
   #   # be backed up, etc.
   #
   #   # Instead of Using a NFSCP, let's use the NFS Server that's created in
   #   # the cluster.
   #   # $HELM install \
   #   #              --set nfs.server=$NFS_SERVER \
   #   #              --set nfs.path=$NFS_PATH \
   #   #              --set storageClass.name=$ELK_STORAGE_CLASS_NAME \
   #   #              --namespace $NAMESPACE \
   #   #              $NFSCP_NAME stable/nfs-client-provisioner
   #
   #   # create the ELK PVC dynamicly
   #   export PVC_NAME=$ELK_PVC_NAME
   #   # Use the "nfs" storage class from the NFS server that's created in the
   #   # cluster.
   #   # export PVC_STORAGE_CLASS_NAME=$ELK_STORAGE_CLASS_NAME
   #   export PVC_STORAGE_CLASS_NAME="nfs"
   #   export PVC_STORAGE_REQUESTED=$ELK_PVC_STORAGE_SIZE
   #   cat $K8S_DEVOPS_CORE_HOME/elasticsearch/pvc-template.yaml | envsubst | \
   #       kubectl create -n $NAMESPACE -f -
   #   # create the ELK via a static YAML file
   #   # kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage.yaml
   # fi

   createNFSPVC "elk-pvc" $NFS_PROVISIONER_NAME "5Gi"

   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch.yaml
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/es-service.yaml

   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl apply -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/logstash/
   echo "# end deploying ELK"
}


function deleteELK(){
   echo "# deleting ELK"
   # delete ELK
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/es-service.yaml
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch.yaml
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/logstash/

   deleteNFSPVC "elk-pvc" $NFS_PROVISIONER_NAME "5Gi"

   # if $GKE_DEPLOYMENT; then
   #   # delete persistent storage for GKE
   #   kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage-gke.yaml
   # else
   #   # delete persistent storage for bare-metal k8s
   #   # delete ELK PVC that was created dynamicly from a template
   #   export PVC_NAME=$ELK_PVC_NAME
   #   export PVC_STORAGE_CLASS_NAME=$ELK_STORAGE_CLASS_NAME
   #   export PVC_STORAGE_REQUESTED=$ELK_PVC_STORAGE_SIZE
   #   cat $K8S_DEVOPS_CORE_HOME/elasticsearch/pvc-template.yaml | envsubst | \
   #       kubectl delete -n $NAMESPACE -f -
   #   # delete ELK PVS created from a static YAML file
   #   # kubectl delete -n $NAMESPACE -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/elasticsearch-storage.yaml
   #
   #   $HELM delete --namespace $NAMESPACE $NFSCP_NAME
   # fi

   echo "# end deleting ELK"
}


function deployNFS(){
   # An NFS server is deployed within the cluster since GKE does not support
   # a PV that is ReadWriteMany.
   echo "# deploying NFS"
   echo "executing $HELM install $NFS_PROVISIONER_NAME -n $NAMESPACE"
   $HELM install $NFS_PROVISIONER_NAME -n $NAMESPACE --set persistence.enabled=$NFS_PROVISIONER_PERSISTENCE_ENABLED,persistence.size=$NFS_PROVISIONER_PERSISTENCE_SIZE stable/nfs-server-provisioner
   echo "# end deploying NFS"
}


function deleteNFS(){
   echo "# deleting NFS"
   echo "executing $HELM delete $NFS_PROVISIONER_NAME"
   $HELM delete $NFS_PROVISIONER_NAME
   echo "# end deleting NFS"
}


function createNFSPVC(){
   export PVC_NAME=$1
   export PVC_STORAGE_CLASS_NAME=$2
   export PVC_STORAGE_SIZE=$3
   echo "# creating $PVC_NAME PVC"
   cat $K8S_DEVOPS_CORE_HOME/nfs-server/pvc-template.yaml | envsubst | \
       kubectl create -n $NAMESPACE -f -
   echo "# $PVC_NAME PVC created"
}


function deleteNFSPVC(){
    export PVC_NAME=$1
    export PVC_STORAGE_CLASS_NAME=$2
    export PVC_STORAGE_SIZE=$3
    echo "# deleting $PVC_NAME PVC"
    cat $K8S_DEVOPS_CORE_HOME/nfs-server/pvc-template.yaml | envsubst | \
        kubectl delete -n $NAMESPACE -f -
    echo "# $PVC_NAME PVC deleted"
}


function deployCAT(){
   echo "# deploying CAT"
   createNFSPVC "cloud-top" $NFS_PROVISIONER_NAME "5Gi"
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
   echo "executing $HELM install $CAT_NAME $CAT_HELM_DIR -n $NAMESPACE"
   $HELM install $CAT_NAME $CAT_HELM_DIR -n $NAMESPACE --debug --logtostderr
   # pause to allow for previous deployments
   # POST_INSTALL_WAIT="15"
   # echo "Waiting $POST_INSTALL_WAIT seconds for CAT deployment to progress."
   # sleep $POST_INSTALL_WAIT
   echo "# end deploying CAT"
}

function deleteCAT(){
  echo "# deleting CAT"
   echo "executing $HELM delete $CAT_NAME"
   $HELM delete $CAT_NAME
   deleteNFSPVC "cloud-top" $NFS_PROVISIONER_NAME "5Gi"
   echo "# end deleting CAT"
}

case $APPS_ACTION in
  deploy)
    case $APP in
      all)
        deployNFS
        # createNFSPVC "cloud-top" $NFS_PROVISIONER_NAME "5Gi"
        # createNFSPVC "elk-pvc" $NFS_PROVISIONER_NAME "5Gi"
        # createNFSPVC "deepgtex-prp" $NFS_PROVISIONER_NAME "5Gi"
        deployELK
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
        # createNFSPVC "cloud-top" $NFS_PROVISIONER_NAME "5Gi"
        # createNFSPVC "elk-pvc" $NFS_PROVISIONER_NAME "5Gi"
        # createNFSPVC "deepgtex-prp" $NFS_PROVISIONER_NAME "5Gi"
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
        # deleteNFSPVC "cloud-top" $NFS_PROVISIONER_NAME "5Gi"
        # deleteNFSPVC "elk-pvc" $NFS_PROVISIONER_NAME "5Gi"
        # deleteNFSPVC "deepgtex-prp" $NFS_PROVISIONER_NAME "5Gi"
        deleteNFS
        ;;
      cat)
        deleteCAT
        ;;
      elk)
        deleteELK
        ;;
      nfs)
        # deleteNFSPVC "cloud-top" $NFS_PROVISIONER_NAME "5Gi"
        # deleteNFSPVC "elk-pvc" $NFS_PROVISIONER_NAME "5Gi"
        # deleteNFSPVC "deepgtex-prp" $NFS_PROVISIONER_NAME "5Gi"
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
