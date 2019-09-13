#!/bin/bash -x
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

set -e
PROJECT=${PROJECT-stage-mvp}
REGION=${REGION-us-east4}
ZONE_EXTENSION=${ZONE_EXTENSION-b}
ZONE=${REGION}-${ZONE_EXTENSION}
CLUSTER_ENV=${CLUSTER_ENV-dev}
CLUSTER_NAME=${CLUSTER_NAME-stage-${CLUSTER_ENV}}
CLUSTER_VERSION=${CLUSTER_VERSION-1.13.6-gke.13}
MACHINE_TYPE=${MACHINE_TYPE-n1-standard-8}
ACCELERATOR_TYPE=${ACCELERATOR_TYPE-""}
ACCELERATOR_COUNT=${ACCELERATOR_COUNT-1}
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
external_ip_name=${CLUSTER_NAME}-external-ip
HELIUM_GKE_HOME=${HELIUM_GKE_HOME-$(pwd)/../..}
# NFS_STORAGE_NAME also needs to be changed in the NFS server YAML.
NFS_STORAGE_NAME=${NFS_STORAGE_NAME-gce-nfs-disk}
NFS_STORAGE_SIZE=${NFS_STORAGE_SIZE-10GB}
KUBECONFIG_DIR=${HELIUM_GKE_HOME}/kubeconfigs/${PROJECT}-${CLUSTER_NAME}
KUBECONFIG=${KUBECONFIG_DIR}/config
KUBECONFIG_USER=${PROJECT}-${CLUSTER_NAME}-admin-user

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

  gcloud container clusters create $CLUSTER_NAME --zone $ZONE \
    --cluster-version $CLUSTER_VERSION --machine-type $MACHINE_TYPE \
    --scopes "https://www.googleapis.com/auth/ndev.clouddns.readwrite","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
    --node-version $CLUSTER_VERSION --num-nodes $NUM_NODES \
    --enable-ip-alias \
    --network $INT_NETWORK \
    --project $PROJECT --enable-basic-auth $EXTRA_CREATE_ARGS;

  if ${USE_STATIC_IP}; then
    gcloud compute addresses create $external_ip_name --region $REGION --project $PROJECT;
    address=$(gcloud compute addresses describe $external_ip_name --region $REGION --project $PROJECT --format='value(address)');
    echo "\n#####"
    echo "Successfully provisioned external IP address $address , You need to add an A record to the DNS name to point to this address. See https://gitlab.com/charts/gitlab/blob/master/doc/installation/cloud/gke.md#dns-entry.";
    echo "#####\n"
  fi

  mkdir -p $KUBECONFIG_DIR
  # Erase k8s config if there.
  echo "" > $KUBECONFIG_DIR/config

  gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT;

  # Create roles for RBAC Helm
  if $RBAC_ENABLED; then
    echo "Creating RBAC binding for HELM tiller account."
    status_code=$(curl -L -w '%{http_code}' -o rbac-config.yaml -s "https://gitlab.com/charts/gitlab/raw/master/doc/installation/examples/rbac-config.yaml");
    if [ "$status_code" != 200 ]; then
      echo "Failed to download rbac-config.yaml, status code: $status_code";
      exit 1;
    fi

    kubectl config set-credentials ${KUBECONFIG_USER} --username=admin --password=$(cluster_admin_password_gke)
    kubectl create --user=${KUBECONFIG_USER} -f rbac-config.yaml;
  fi

  # deploy tiller here?

  echo "###"
  echo "For kubectl configuration of this cluster only:"
  echo "  export KUBECONFIG=$KUBECONFIG"
  echo "To add to your own kubectl configurations use:"
  echo "  export KUBECONFIG=\$KUBECONFIG:$KUBECONFIG"
  echo "###"
}


#Deletes everything created during bootstrap
function cleanup_gke_resources(){
  validate_required_tools;
  gcloud container clusters delete -q $CLUSTER_NAME --zone $ZONE --project $PROJECT;
  echo "Deleted $CLUSTER_NAME cluster successfully";
  if ${USE_STATIC_IP}; then
    gcloud compute addresses delete -q $external_ip_name --region $REGION --project $PROJECT;
    echo "Deleted ip: $external_ip_name successfully";
  fi
  echo "\033[;33m Warning: Disks, load balancers, DNS records, and other cloud resources created during the helm deployment are not deleted, please delete them manually from the gcp console \033[0m";
}

function createNodePool(){
   if ! [ -z "${ACCELERATOR_TYPE}" ]; then
     EXTRA_CREATE_ARGS="--accelerator type=${ACCELERATOR_TYPE},count=${ACCELERATOR_COUNT}"
   fi

   echo "creating NodePool with name $1"
   gcloud container node-pools create $1 \
   ${EXTRA_CREATE_ARGS} \
   --zone ${ZONE} --project $PROJECT --cluster ${CLUSTER_NAME} \
   --num-nodes ${NUM_POOL_NODES} --min-nodes ${MIN_POOL_NODES} \
   --max-nodes ${MAX_POOL_NODES} --enable-autoscaling \
   --machine-type ${MACHINE_TYPE} --node-labels=pool-name=$1

   if ! [ -z "${ACCELERATOR_TYPE}" ]; then
     sleep 15 # Wait a little for nodes to come up.
     # Deploy Nvidia device drivers to the nodes if an accelerator is used.
     kubectl apply --user=${KUBECONFIG_USER} -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/master/nvidia-driver-installer/cos/daemonset-preloaded.yaml
   fi
}

function deleteNodePool(){
   echo "deleting NodePool with name $1"
   yes | gcloud container node-pools delete $1 \
   --zone ${ZONE} --project $PROJECT --cluster ${CLUSTER_NAME}
}

function deployELKNFS(){
   echo "deploying ELK and NFS"
   # deploy ELK
   kubectl apply --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/elasticsearch/
   kubectl apply --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/kibana/
   kubectl apply --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/logstash/

   # create disk for persistent storage
   gcloud compute disks create $NFS_STORAGE_NAME --size $NFS_STORAGE_SIZE \
          --zone $ZONE --project $PROJECT
   # deploy NFS server
   kubectl apply --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/nfs-server/
}

function deleteELKNFS(){
   echo "deleting ELK and NFS"
   # delete ELK
   kubectl delete --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/elasticsearch/
   kubectl delete --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/kibana/
   kubectl delete --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/logstash/

   # delete NFS server
   kubectl delete --user=${KUBECONFIG_USER} -R -f $HELIUM_GKE_HOME/nfs-server/
   # delete disk for persistent storage
   SLEEP_TIME=30
   echo "Waiting for $SLEEP_TIME seconds for NFS server deletion."
   sleep $SLEEP_TIME
   gcloud compute disks delete $NFS_STORAGE_NAME \
          --zone $ZONE --project $PROJECT -q
}

if [ -z "$1" ]; then
  echo "Supported commands: createCluster, deleteCluster, createNodePool, deleteNodePool";
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
  deployELKNFS)
    deployELKNFS;
    ;;
  deleteELKNFS)
    deleteELKNFS;
    ;;
  createClusterELKNFS)
    bootstrap;
    deployELKNFS;
    ;;
  deleteClusterELKNFS)
    deleteELKNFS;
    cleanup_gke_resources;
    ;;
  *)
    echo "Unknown command $1";
    exit 1;
  ;;
esac
