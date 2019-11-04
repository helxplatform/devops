#!/bin/bash
# This bash script shall create a GKE cluster, an external IP, setup kubectl to
# connect to the cluster without changing the home kube config and finally installs
# helm with the appropriate service account if RBAC is enabled

# * Create a script using gcloud commands, etc to:
# * Create two new identical clusters called stage-dev and stage-prod.
# * Add the following node pools to both clusters with these machine types:
#    * default: n1-standard-2
#    * medium: n1-standard-8
#    * medium-dl: n1-standard-8 + GPUs
#       * dev: 1 Tesla V100
#       * prod: 4 Tesla V100
# * The above node pools need to
#    * Autoscale to a maximum of two nodes.
#    * Downscale to zero
#    * Use preemptible instances
# * Create or reuse a disk to be the backing store for an NFS PersistentVolume.
#    * For now, a 10GB SSD
# * Execute the stage basic devops install after:
#    * Deleting RStudio kubernetes yaml
#    * Adding NFS PersistentVolume and PersistentVolumeClaim deployment
# * Add the parameterizable script for all of the above steps to the devops repo.
# * Delete all old GKE clusters.
#

# To override the variables below you can can export them out in a file and
# then set the variable "GKE_CLUSTER_CONFIG" to the location of that file.
# Setting at least CLUSTER_NAME, e.g., "pjl-stage", would be good for developer
# testing.
if  [ -z ${GKE_CLUSTER_CONFIG+x} ]
then
  echo "Using values from shell or defaults in this script."
else
  echo "Sourcing ${GKE_CLUSTER_CONFIG}"
  source ${GKE_CLUSTER_CONFIG}
fi

set -e
#
# default user-definable variable definitions
#
#PROJECT=${PROJECT-stage-mvp}
#PROJECT=${PROJECT-research-237918}
PROJECT=${PROJECT-stack-dev-237116}
REGION=${REGION-us-east1}
ZONE_EXTENSION=${ZONE_EXTENSION-b}
CLUSTER_ENV=${CLUSTER_ENV-dev}
CLUSTER_NAME=${CLUSTER_NAME-${USER}-stage}
CLUSTER_VERSION=${CLUSTER_VERSION-1.13.11-gke.9}
MACHINE_TYPE=${MACHINE_TYPE-n1-standard-2}
ADD_CLUSTER_ACCELERATOR=${ADD_CLUSTER_ACCELERATOR-false}
CLUSTER_ACCELERATOR_TYPE=${CLUSTER_ACCELERATOR_TYPE-"nvidia-tesla-p100"}
CLUSTER_ACCELERATOR_COUNT=${CLUSTER_ACCELERATOR_COUNT-1}
NP_ACCELERATOR_TYPE=${NP_ACCELERATOR_TYPE-"nvidia-tesla-p100"}
NP_ACCELERATOR_COUNT=${NP_ACCELERATOR_COUNT-1}
RBAC_ENABLED=${RBAC_ENABLED-true}
NUM_NODES=${NUM_NODES-2}
MIN_NODES=${MIN_NODES-0}
MAX_NODES=${MAX_NODES-2}
NUM_POOL_NODES=${NUM_POOL_NODES-2}
MIN_POOL_NODES=${MIN_POOL_NODES-0}
MAX_POOL_NODES=${MAX_POOL_NODES-3}
INT_NETWORK=${INT_NETWORK-default}
PREEMPTIBLE=${PREEMPTIBLE-false}
EXTRA_CREATE_ARGS=${EXTRA_CREATE_ARGS-""}
USE_STATIC_IP=${USE_STATIC_IP-false}
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-$(pwd)/../..}
HELIUMPLUSDATASTAGE_HOME=${HELIUMPLUSDATASTAGE_HOME-${K8S_DEVOPS_CORE_HOME}/..}
HELIUMDATACOMONS_HOME=${HELIUMDATACOMONS_HOME-${HELIUMPLUSDATASTAGE_HOME}/../heliumdatacommons}
COMMONSSHARE_K8S=${COMMONSSHARE_K8S-${HELIUMDATACOMONS_HOME}/commonsshare/k8s}
TYCHO_K8S=${TYCHO_K8S-${HELIUMPLUSDATASTAGE_HOME}/tycho/kubernetes}
#
# end default user-definable variable definitions
#

CLUSTER_NAME_ENV=${CLUSTER_NAME}-${CLUSTER_ENV}
KUBECONFIG_DIR=${KUBECONFIG_DIR-${K8S_DEVOPS_CORE_HOME}/kubeconfigs/${PROJECT}-${CLUSTER_NAME_ENV}}
ZONE=${REGION}-${ZONE_EXTENSION}
USER_KUBECONFIG=$KUBECONFIG
SCRIPT_KUBECONFIG=${KUBECONFIG_DIR}/config
KUBECONFIG=${SCRIPT_KUBECONFIG}
KUBECONFIG_USER=${PROJECT}-${CLUSTER_NAME_ENV}-admin-user
external_ip_name=${CLUSTER_NAME_ENV}-external-ip

# MacOS does not support readlink, but it does have perl
KERNEL_NAME=$(uname -s)
if [ "${KERNEL_NAME}" = "Darwin" ]; then
  SCRIPT_PATH=$(perl -e 'use Cwd "abs_path";use File::Basename;print dirname(abs_path(shift))' "$0")
else
  SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
fi

# We seem to need common.sh
source $SCRIPT_PATH/common.sh;

function bootstrap(){
  set -e
  validate_required_tools;

  # Use the default cluster version for the specified zone if not provided
  if [ -z "${CLUSTER_VERSION}" ]; then
    CLUSTER_VERSION=$(gcloud container get-server-config --zone $ZONE --project $PROJECT --format='value(defaultClusterVersion)');
  fi

  if $PREEMPTIBLE; then
    EXTRA_CREATE_ARGS="$EXTRA_CREATE_ARGS --preemptible"
  fi

  if ${ADD_CLUSTER_ACCELERATOR}; then
    echo "Adding accelerator to base cluster."
    EXTRA_CREATE_ARGS="$EXTRA_CREATE_ARGS --accelerator type=${CLUSTER_ACCELERATOR_TYPE},count=${CLUSTER_ACCELERATOR_COUNT}"
  else
    echo "Not adding accelerator to base cluster."
  fi

  gcloud container clusters create $CLUSTER_NAME_ENV --zone $ZONE \
    --cluster-version $CLUSTER_VERSION --machine-type $MACHINE_TYPE \
    --scopes "https://www.googleapis.com/auth/ndev.clouddns.readwrite",\
"https://www.googleapis.com/auth/compute",\
"https://www.googleapis.com/auth/devstorage.read_only",\
"https://www.googleapis.com/auth/logging.write",\
"https://www.googleapis.com/auth/monitoring",\
"https://www.googleapis.com/auth/servicecontrol",\
"https://www.googleapis.com/auth/service.management.readonly",\
"https://www.googleapis.com/auth/trace.append" \
    --node-version $CLUSTER_VERSION --num-nodes $NUM_NODES \
    --enable-ip-alias --network $INT_NETWORK \
    --project $PROJECT --enable-basic-auth $EXTRA_CREATE_ARGS;

  if ${USE_STATIC_IP}; then
    gcloud compute addresses create $external_ip_name --region $REGION --project $PROJECT;
    address=$(gcloud compute addresses describe $external_ip_name --region $REGION --project $PROJECT --format='value(address)');
    echo "\n#####"
    echo "Successfully provisioned external IP address $address , You need to add an A record to the DNS name to point to this address. See https://gitlab.com/charts/gitlab/blob/master/doc/installation/cloud/gke.md#dns-entry.";
    echo "#####\n"
  fi

  echo "saving kubeconfig credentials to $KUBECONFIG_DIR/config"
  # Save new cluster kubeconfig in local directory.
  mkdir -p $KUBECONFIG_DIR
  # Erase k8s config if there.
  echo "" > $KUBECONFIG_DIR/config
  gcloud container clusters get-credentials $CLUSTER_NAME_ENV --zone $ZONE --project $PROJECT;

  # Add new cluster kubeconfig to user's kubeconfig.
  KUBECONFIG=$USER_KUBECONFIG
  echo "adding kubeconfig credentials to $KUBECONFIG"
  gcloud container clusters get-credentials $CLUSTER_NAME_ENV --zone $ZONE --project $PROJECT;
  # add a 'user' in user's kubeconfig
  # This is giving an error and don't think it is used elsewhere, so commenting out.
  # echo "adding kubeconfig username/password credentials to $KUBECONFIG"
  # kubectl config set-credentials ${KUBECONFIG_USER} --username=admin --password=$(cluster_admin_password_gke)
  KUBECONFIG=$SCRIPT_KUBECONFIG

  # Create roles for RBAC Helm
  if $RBAC_ENABLED; then
    echo "Creating RBAC binding for HELM tiller account."
    status_code=$(curl -L -w '%{http_code}' -o rbac-config.yaml -s "https://gitlab.com/charts/gitlab/raw/master/doc/installation/examples/rbac-config.yaml");
    if [ "$status_code" != 200 ]; then
      echo "Failed to download rbac-config.yaml, status code: $status_code";
      exit 1;
    fi
    kubectl create -f rbac-config.yaml;
  fi

  if ${ADD_CLUSTER_ACCELERATOR}; then
    installAcceleratorDaemonset
  fi

  # deploy tiller here?

  echo "######"
  echo "For kubectl configuration of this cluster only:"
  echo "  export KUBECONFIG=$KUBECONFIG"
  echo "To add to your own kubectl configurations use:"
  echo "  export KUBECONFIG=\$KUBECONFIG:$KUBECONFIG"
  echo "######"
}


#Deletes everything created during bootstrap
function cleanup_gke_resources(){
  validate_required_tools;
  gcloud container clusters delete -q $CLUSTER_NAME_ENV --zone $ZONE --project $PROJECT;
  echo "Deleted $CLUSTER_NAME_ENV cluster successfully";
  if ${USE_STATIC_IP}; then
    gcloud compute addresses delete -q $external_ip_name --region $REGION --project $PROJECT &&
    echo "Deleted ip: $external_ip_name successfully";
  fi
  echo "######"
  echo "Warning: Disks, load balancers, DNS records, and other cloud resources"
  echo "created during the deployment are not deleted, please delete them"
  echo "manually from the gcp console.  Check disks that start with:"
  echo "  gke-${CLUSTER_NAME_ENV}-"
  echo "######";
}

function createNodePool(){
   if ! [ -z "${NP_ACCELERATOR_TYPE}" ]; then
     EXTRA_CREATE_ARGS="--accelerator type=${NP_ACCELERATOR_TYPE},count=${NP_ACCELERATOR_COUNT}"
   fi

   echo "creating NodePool with name $1"
   gcloud container node-pools create $1 \
   ${EXTRA_CREATE_ARGS} \
   --zone ${ZONE} --project $PROJECT --cluster ${CLUSTER_NAME_ENV} \
   --num-nodes ${NUM_POOL_NODES} --min-nodes ${MIN_POOL_NODES} \
   --max-nodes ${MAX_POOL_NODES} --enable-autoscaling \
   --machine-type ${MACHINE_TYPE} --node-labels=pool-name=$1

   if ! [ -z "${NP_ACCELERATOR_TYPE}" ]; then
     installAcceleratorDaemonset
   fi
}

function installAcceleratorDaemonset(){
  sleep 15 # Wait a little for nodes to come up.
  # Deploy Nvidia device drivers to the nodes if an accelerator is used.
  kubectl create -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml
  # If there are problems with the GPU then might want to try the one below.
  # kubectl create -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/stable/daemonset.yaml
}

function deleteNodePool(){
   echo "deleting NodePool with name $1"
   yes | gcloud container node-pools delete $1 \
   --zone ${ZONE} --project $PROJECT --cluster ${CLUSTER_NAME_ENV}
}

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
  echo "Supported commands: createCluster, deleteCluster, createNodePool, deleteNodePool, choas, deployELK, deleteELK, createClusterELK, deleteClusterELK, deployNFS, deleteNFS, createClusterNFS, deleteClusterNFS, deployCommonsShare, deleteCommonsShare, deployTycho, deleteTycho, createClusterAll, deleteClusterAll";
  exit
fi


case $1 in
  createCluster)
    bootstrap;
    ;;
  deleteCluster)
    cleanup_gke_resources;
    ;;
  createNodePool)
    if [ -z "$2" ]; then
       echo "createNodePool requires a node pool name";
       exit
    fi
    createNodePool $2;
    ;;
  deleteNodePool)
    if [ -z "$2" ]; then
       echo "deleteNodePool requires a node pool name";
       exit
    fi
    deleteNodePool $2;
    ;;
  chaos)
    $SCRIPT_PATH/kube-monkey.sh;
    ;;
  deployELK)
    deployELK;
    ;;
  deleteELK)
    deleteELK;
    ;;
  createClusterELK)
    bootstrap;
    deployELK;
    ;;
  deleteClusterELK)
    deleteELK;
    cleanup_gke_resources;
    ;;
  deployNFS)
    deployNFS;
    ;;
  deleteNFS)
    deleteNFS;
    ;;
  createClusterNFS)
    bootstrap;
    deployNFS;
    ;;
  deleteClusterNFS)
    deleteNFS;
    cleanup_gke_resources;
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
  createClusterAll)
    bootstrap;
    deployELK;
    deployNFS;
    commonsShare create;
    tycho create;
    ;;
  deleteClusterAll)
    tycho delete;
    commonsShare delete;
    deleteELK;
    deleteNFS;
    cleanup_gke_resources;
    ;;
  *)
    echo "Unknown command $1";
    exit 1;
  ;;
esac
