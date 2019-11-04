#!/bin/bash

#
# Install base applications to Kubernetes cluster.
#

# To override the variables below you can can export them out in a file and
# then set the variable "GKE_CLUSTER_CONFIG" to the location of that file.
# Setting at least CLUSTER_NAME, e.g., "pjl-stage", would be good for developer
# testing.
if  [ -z ${GKE_CLUSTER_CONFIG+x} ]
then
  echo "Using values from shell or defaults in this script."
else
  if [ "$1" == "loadFunctions" ]
  then
    echo "Ignoring GKE_CLUSTER_CONFIG and only loading functions."
  else
    echo "Sourcing ${GKE_CLUSTER_CONFIG}"
    source ${GKE_CLUSTER_CONFIG}
  fi
fi

set -e

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
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-${SCRIPT_PATH}/..}
HELIUMPLUSDATASTAGE_HOME=${HELIUMPLUSDATASTAGE_HOME-${K8S_DEVOPS_CORE_HOME}/..}
HELIUMDATACOMONS_HOME=${HELIUMDATACOMONS_HOME-${HELIUMPLUSDATASTAGE_HOME}/../heliumdatacommons}
COMMONSSHARE_K8S=${COMMONSSHARE_K8S-${HELIUMDATACOMONS_HOME}/commonsshare/k8s}
TYCHO_K8S=${TYCHO_K8S-${HELIUMPLUSDATASTAGE_HOME}/tycho/kubernetes}
#
# end default user-definable variable definitions
#

function deployELK(){
   echo "deploying ELK"
   # deploy ELK
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/logstash/
}

function deleteELK(){
   echo "deleting ELK and NFS"
   # delete ELK
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/elasticsearch/
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/kibana/
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/logstash/
}

function deployNFS(){
   # An NFS server is deployed within the cluster since GKE does not support
   # a PV that is ReadWriteMany.
   echo "deploying NFS"
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-pvc.yaml
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server.yaml
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc.yaml
   # deploy NFS PVC for NFS clients
   kubectl apply -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-pvc-pv.yaml
}

function deleteNFS(){
   echo "deleting NFS"
   # delete NFS server
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-pvc-pv.yaml
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-svc.yaml
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server.yaml
   kubectl delete -R -f $K8S_DEVOPS_CORE_HOME/nfs-server/nfs-server-pvc.yaml
}

function commonsShare(){
   echo "executing kubectl $1 on CommonsShare YAMLs"
   kubectl $1 -f $COMMONSSHARE_K8S/postgis-claim0-persistentvolumeclaim.yaml,$COMMONSSHARE_K8S/postgis-deployment.yaml,$COMMONSSHARE_K8S/hydroshare-service.yaml,$COMMONSSHARE_K8S/solr-deployment.yaml,$COMMONSSHARE_K8S/hydroshare-env-configmap.yaml,$COMMONSSHARE_K8S/hydroshare-secret.yaml,$COMMONSSHARE_K8S/postgis-service.yaml,$COMMONSSHARE_K8S/solr-service.yaml,$COMMONSSHARE_K8S/hydroshare-deployment.yaml
}

function tycho(){
   echo "executing kubectl $1 on tycho YAMLs"
   kubectl $1 -f $TYCHO_K8S/
}

if [ -z "$1" ]; then
  echo "Supported commands: deployELKNFS, deleteELKNFS, deployCommonsShare, deleteCommonsShare, deployTycho, deleteTycho, createAll, deleteAll";
  exit
fi


case $1 in
  deployELK)
    deployELK;
    ;;
  deleteELK)
    deleteELK;
    ;;
  deployNFS)
    deployNFS;
    ;;
  deleteNFS)
    deleteNFS;
    ;;
  deployCommonsShare)
    commonsShare create;
    ;;
  deleteCommonsShare)
    commonsShare delete;
    ;;
  deployTycho)
    tycho create;
    ;;
  deleteTycho)
    tycho delete;
    ;;
  deployAll)
    deployELK;
    deployNFS;
    commonsShare create;
    tycho create;
    ;;
  deleteAll)
    tycho delete;
    commonsShare delete;
    deleteNFS;
    deleteELK;
    ;;
  loadFunctions)
    echo "just loding functions"
    ;;
  *)
    echo "Unknown command $1";
    exit 1;
  ;;
esac
