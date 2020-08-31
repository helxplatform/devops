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

# expand variables and print commands
#set -x

function print_help() {
  echo "\
usage: $0 <action> <app> <option>
  actions: deploy, delete
  apps: cat, cluster, elk, nfs, node-pool, all
      note: all does not create a node pool
  --np-name [name]  Specify node pool name if deploying a node pool
  -c [config file]  Specify config file.
  -h|--help         Print this help message.
"
}

if [[ $# = 0 ]]; then
  print_help
  exit 1
fi

while [[ $# > 0 ]]
  do
  key="$1"
  case $key in
    -h|--help)
      print_help
      exit 0
      ;;
    deploy)
      ACTION="deploy"
      APP="$2"
      shift
      ;;
    delete)
      ACTION="delete"
      APP="$2"
      shift
      ;;
    --np-name)
      NP_NAME="$2"
      shift
      ;;
    -c)
      CLUSTER_CONFIG="$2"
      shift
      ;;
    *)
      # unknown option
      print_help
      exit 1
      ;;
  esac
  shift # past argument or value
done

# To override the variables below you can can export them out in a file and
# then set the variable "CLUSTER_CONFIG" to the location of that file.
# Setting at least CLUSTER_NAME, e.g., "pjl-stage", would be good for developer
# testing.
if  [ -z ${CLUSTER_CONFIG+x} ]
then
  echo "gke-cluster.sh: Using values from shell or defaults in this script."
else
  echo "gke-cluster.sh: Sourcing ${CLUSTER_CONFIG}"
  source ${CLUSTER_CONFIG}
fi
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
PROJECT=${PROJECT-"A_GOOGLE_PROJECT_ID"}
REGION=${REGION-us-east1}
ZONE_EXTENSION=${ZONE_EXTENSION-b}
CLUSTER_ENV=${CLUSTER_ENV-dev}
CLUSTER_NAME=${CLUSTER_NAME-${USER}-cluster}
CLUSTER_VERSION=${CLUSTER_VERSION-1.15.12-gke.2}
MACHINE_TYPE=${MACHINE_TYPE-n1-standard-2}
ADD_CLUSTER_ACCELERATOR=${ADD_CLUSTER_ACCELERATOR-false}
NP_NAME=${NP_NAME-"custom-node-pool"}
CLUSTER_ACCELERATOR_TYPE=${CLUSTER_ACCELERATOR_TYPE-"nvidia-tesla-p100"}
CLUSTER_ACCELERATOR_COUNT=${CLUSTER_ACCELERATOR_COUNT-1}
NP_ACCELERATOR_TYPE=${NP_ACCELERATOR_TYPE-"nvidia-tesla-p100"}
NP_ACCELERATOR_COUNT=${NP_ACCELERATOR_COUNT-1}
RBAC_ENABLED=${RBAC_ENABLED-true}
NUM_NODES=${NUM_NODES-2}
MIN_NODES=${MIN_NODES-1}
MAX_NODES=${MAX_NODES-4}
NUM_POOL_NODES=${NUM_POOL_NODES-2}
MIN_POOL_NODES=${MIN_POOL_NODES-0}
MAX_POOL_NODES=${MAX_POOL_NODES-4}
INT_NETWORK=${INT_NETWORK-default}
PREEMPTIBLE=${PREEMPTIBLE-false}
MASTER_AUTHORIZED_NETWORKS=${MASTER_AUTHORIZED_NETWORKS-0.0.0.0/0}
# Define MASTER_AUTHORIZED_NETWORKS_OPTIONS to be "" to disable master
# authorized networks.
MASTER_AUTHORIZED_NETWORKS_OPTIONS=${MASTER_AUTHORIZED_NETWORKS_OPTIONS-"--enable-master-authorized-networks --master-authorized-networks $MASTER_AUTHORIZED_NETWORKS"}
EXTRA_CREATE_ARGS=${EXTRA_CREATE_ARGS-""}
USE_STATIC_IP=${USE_STATIC_IP-false}
K8S_DEVOPS_CORE_HOME=${K8S_DEVOPS_CORE_HOME-${SCRIPT_PATH}/..}
POST_CLUSTER_WAIT=${POST_CLUSTER_WAIT-60}

#
# end default user-definable variable definitions
#

CLUSTER_NAME_ENV=${CLUSTER_NAME}-${CLUSTER_ENV}
KUBECONFIG_DIR=${KUBECONFIG_DIR-${K8S_DEVOPS_CORE_HOME}/kubeconfigs/${PROJECT}-${CLUSTER_NAME_ENV}}
ZONE=${REGION}-${ZONE_EXTENSION}
USER_KUBECONFIG=$KUBECONFIG
SCRIPT_KUBECONFIG=${KUBECONFIG_DIR}/config
export KUBECONFIG=${SCRIPT_KUBECONFIG}
KUBECONFIG_USER=${PROJECT}-${CLUSTER_NAME_ENV}-admin-user
external_ip_name=${CLUSTER_NAME_ENV}-external-ip

# We seem to need common.sh
source $SCRIPT_PATH/gke-common.sh;
source $SCRIPT_PATH/k8s-apps.sh loadFunctions;


function deployCluster(){
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
"https://www.googleapis.com/auth/devstorage.read_write",\
"https://www.googleapis.com/auth/logging.write",\
"https://www.googleapis.com/auth/monitoring",\
"https://www.googleapis.com/auth/servicecontrol",\
"https://www.googleapis.com/auth/service.management.readonly",\
"https://www.googleapis.com/auth/trace.append" \
    --node-version $CLUSTER_VERSION --num-nodes $NUM_NODES --project $PROJECT \
    --enable-ip-alias \
    $MASTER_AUTHORIZED_NETWORKS_OPTIONS \
    --network $INT_NETWORK $EXTRA_CREATE_ARGS;



    # --enable-basic-auth
    # --enable-ip-alias --enable-private-nodes --enable-master-authorized-networks \

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
  # This is giving an error and don't think it is used elsewhere, so commenting
  # out.  Maybe it needs to be after the HELM RBAC configuration.
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
  echo "Waiting $POST_CLUSTER_WAIT seconds for cluster to settle..."
  sleep $POST_CLUSTER_WAIT
}


#Deletes everything created during bootstrap
function deleteCluster(){
  validate_required_tools;
  gcloud container clusters delete -q $CLUSTER_NAME_ENV --zone $ZONE --project $PROJECT;
  echo "Deleted $CLUSTER_NAME_ENV cluster successfully";
  if ${USE_STATIC_IP}; then
    gcloud compute addresses delete -q $external_ip_name --region $REGION --project $PROJECT &&
    echo "Deleted ip: $external_ip_name successfully";
  fi
  echo "######"
  echo "Warning: Disks, load balancers, DNS records, and other cloud resources"
  echo "created during the deployment might not be deleted, please delete them"
  echo "manually from the gcp console.  Check disks that start with:"
  echo "  gke-${CLUSTER_NAME_ENV}-"
  echo "######";
}


function createNodePool(){
  set -e
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


case $ACTION in
  deploy)
    case $APP in
      all)
        deployCluster
        deployNFS
        deployELK
        deployCAT
        ;;
      cat)
        deployCAT
        ;;
      cluster)
        deployCluster
        ;;
      elk)
        deployELK
        ;;
      nfs)
        deployNFS
        ;;
      node-pool)
        createNodePool $NP_NAME
        ;;
      *)
        print_help
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
        deleteCluster
        ;;
      cat)
        deleteCAT
        ;;
      cluster)
        deleteCluster
        ;;
      elk)
        deleteELK
        ;;
      nfs)
        deleteNFS
        ;;
      node-pool)
        deleteNodePool $NP_NAME
        ;;
      *)
        print_help
        exit 1
        ;;
    esac
    ;;
  loadFunctions)
    echo "just loading functions"
    ;;
  *)
    print_help
    exit 1
    ;;
esac
