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
# These variables can be set outside of this script.
#
#PROJECT=${PROJECT-stage-mvp}
#PROJECT=${PROJECT-research-237918}
PROJECT=${PROJECT-stack-dev-237116}
REGION=${REGION-us-east1}
ZONE_EXTENSION=${ZONE_EXTENSION-b}
CLUSTER_ENV=${CLUSTER_ENV-dev}
CLUSTER_NAME=${CLUSTER_NAME-stage}
CLUSTER_VERSION=${CLUSTER_VERSION-1.13.7-gke.24}
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
HELIUM_GKE_HOME=${HELIUM_GKE_HOME-$(pwd)/../..}
# NFS_STORAGE_NAME also needs to be changed in the NFS server YAML.  Currently
# this is done via an env variable in the YAML.
NFS_STORAGE_SIZE=${NFS_STORAGE_SIZE-10GB}
COMMONSSHARE_K8S=${COMMONSSHARE_K8S-${HELIUM_GKE_HOME}/../../../heliumdatacommons/commonsshare/commonsshare/k8s}
TYCHO_K8S=${TYCHO_K8S-${HELIUM_GKE_HOME}/../../../heliumplus/tycho/tycho/kubernetes}
# POSTGIS_STORAGE_SIZE=${POSTGIS_STORAGE_SIZE-1GB}

# end overridable variables
CLUSTER_NAME_ENV=${CLUSTER_NAME}-${CLUSTER_ENV}
NFS_STORAGE_NAME=${NFS_STORAGE_NAME-gke-${CLUSTER_NAME_ENV}-elk-pd}
KUBECONFIG_DIR=${KUBECONFIG_DIR-${HELIUM_GKE_HOME}/kubeconfigs/${PROJECT}-${CLUSTER_NAME_ENV}}
# POSTGIS_STORAGE_NAME=${POSTGIS_STORAGE_NAME-gke-${CLUSTER_NAME_ENV}-postgis-pd}
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

  # Save new cluster kubeconfig in local directory.
  mkdir -p $KUBECONFIG_DIR
  # Erase k8s config if there.
  echo "" > $KUBECONFIG_DIR/config
  gcloud container clusters get-credentials $CLUSTER_NAME_ENV --zone $ZONE --project $PROJECT;

  # Add new cluster kubeconfig to user's kubeconfig.
  KUBECONFIG=$USER_KUBECONFIG
  gcloud container clusters get-credentials $CLUSTER_NAME_ENV --zone $ZONE --project $PROJECT;
  KUBECONFIG=$SCRIPT_KUBECONFIG
  # add a 'user' in user's kubeconfig
  kubectl --kubeconfig $USER_KUBECONFIG config set-credentials ${KUBECONFIG_USER} --username=admin --password=$(cluster_admin_password_gke)

  # Create roles for RBAC Helm
  if $RBAC_ENABLED; then
    echo "Creating RBAC binding for HELM tiller account."
    status_code=$(curl -L -w '%{http_code}' -o rbac-config.yaml -s "https://gitlab.com/charts/gitlab/raw/master/doc/installation/examples/rbac-config.yaml");
    if [ "$status_code" != 200 ]; then
      echo "Failed to download rbac-config.yaml, status code: $status_code";
      exit 1;
    fi

    # kubectl config set-credentials ${KUBECONFIG_USER} --username=admin --password=$(cluster_admin_password_gke)
    # kubectl create --user=${KUBECONFIG_USER} -f rbac-config.yaml;
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
  # kubectl create -f https://raw.githubusercontent.com/GoogleCloudPlatform/container-engine-accelerators/stable/daemonset.yaml
}

function deleteNodePool(){
   echo "deleting NodePool with name $1"
   yes | gcloud container node-pools delete $1 \
   --zone ${ZONE} --project $PROJECT --cluster ${CLUSTER_NAME_ENV}
}

function deployELKNFS(){
   echo "deploying ELK and NFS"
   # deploy ELK
   kubectl apply -R -f $HELIUM_GKE_HOME/elasticsearch/
   kubectl apply -R -f $HELIUM_GKE_HOME/kibana/
   kubectl apply -R -f $HELIUM_GKE_HOME/logstash/

   # create disk for persistent storage
   gcloud compute disks create $NFS_STORAGE_NAME --size $NFS_STORAGE_SIZE \
          --zone $ZONE --project $PROJECT
   # deploy NFS server
   # deploy all YAML files at once
   # kubectl apply -R -f $HELIUM_GKE_HOME/nfs-server/

   kubectl apply -R -f $HELIUM_GKE_HOME/nfs-server/nfs-pvc-pv.yaml
   export NFS_STORAGE_NAME
   # replace env variable in YAML file NFS_STORAGE_NAME value and deploy inline
   cat $HELIUM_GKE_HOME/nfs-server/nfs-server.template.yaml | envsubst | kubectl apply -R -f -
   # kubectl apply -R -f $HELIUM_GKE_HOME/nfs-server/nfs-server.yaml
   kubectl apply -R -f $HELIUM_GKE_HOME/nfs-server/nfs-service.yaml
}

function deleteELKNFS(){
   echo "deleting ELK and NFS"
   # delete ELK
   kubectl delete -R -f $HELIUM_GKE_HOME/elasticsearch/
   kubectl delete -R -f $HELIUM_GKE_HOME/kibana/
   kubectl delete -R -f $HELIUM_GKE_HOME/logstash/

   # delete NFS server
   # kubectl delete -R -f $HELIUM_GKE_HOME/nfs-server/

   kubectl delete -R -f $HELIUM_GKE_HOME/nfs-server/nfs-pvc-pv.yaml
   export NFS_STORAGE_NAME
   cat $HELIUM_GKE_HOME/nfs-server/nfs-server.template.yaml | envsubst | kubectl delete -R -f -
   # kubectl delete -R -f $HELIUM_GKE_HOME/nfs-server/nfs-server.yaml
   kubectl delete -R -f $HELIUM_GKE_HOME/nfs-server/nfs-service.yaml

   # delete disk for persistent storage
   SLEEP_TIME=30
   echo "Waiting for $SLEEP_TIME seconds for NFS server deletion."
   sleep $SLEEP_TIME
   gcloud compute disks delete $NFS_STORAGE_NAME \
          --zone $ZONE --project $PROJECT -q
}

function commonsShare(){
   echo "executing kubectl $1 on CommonsShare YAMLs"
   # create/delete disk for persistent storage
   # if [ $1 == "create" ]; then
   #   DISKS_EXTRA_OPTIONS="--size $POSTGIS_STORAGE_SIZE"
   # else
   #   DISKS_EXTRA_OPTIONS=""
   # fi
   # gcloud compute disks $1 $POSTGIS_STORAGE_NAME $DISKS_EXTRA_OPTIONS \
   #        --zone $ZONE --project $PROJECT -q
   kubectl $1 -f $COMMONSSHARE_K8S/postgis-claim0-persistentvolumeclaim.yaml,$COMMONSSHARE_K8S/postgis-deployment.yaml,$COMMONSSHARE_K8S/hydroshare-service.yaml,$COMMONSSHARE_K8S/solr-deployment.yaml,$COMMONSSHARE_K8S/hydroshare-env-configmap.yaml,$COMMONSSHARE_K8S/postgis-service.yaml,$COMMONSSHARE_K8S/solr-service.yaml,$COMMONSSHARE_K8S/hydroshare-deployment.yaml
}

function tycho(){
   echo "executing kubectl $1 on tycho YAMLs"
   kubectl $1 -f $TYCHO_K8S/
}

if [ -z "$1" ]; then
  echo "Supported commands: createCluster, deleteCluster, createNodePool, deleteNodePool, choas, deployELKNFS, deleteELKNFS, createClusterELKNFS, deleteClusterELKNFS, deployCommonsShare, deleteCommonsShare, deployTycho, deleteTycho, createClusterAll, deleteClusterAll";
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
    deployELKNFS;
    commonsShare create;
    tycho create;
    ;;
  deleteClusterAll)
    tycho delete;
    commonsShare delete;
    deleteELKNFS;
    cleanup_gke_resources;
    ;;
  *)
    echo "Unknown command $1";
    exit 1;
  ;;
esac
