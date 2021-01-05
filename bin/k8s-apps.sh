#!/bin/bash

#
# Install base applications to Kubernetes cluster.
#

function print_apps_help() {
  echo "\
usage: $0 <action> <app> <option>
  actions: deploy, delete
  apps: all, cat, dug, dugstorage, elk, nginx-revproxy, efk, ambassador,
        appstore, commonsshare, tycho, nextflowstorage, nfs-server, nfsrods
  -c [config file]  Specify config file.
  -d|--debug        Add debug outputs
  -h|--help         Print this help message.
"
}

random-string() {
  env LC_CTYPE=C tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w ${1:-32} | head -n 1
}

if [[ $# = 0 ]]; then
  print_apps_help
  exit 1
fi

HELX_DEBUG=""

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
    -d|--debug)
      HELX_DEBUG="true"
      ;;
    *)
      # unknown option
      print_apps_help
      exit 1
      ;;
  esac
  shift # past argument or value
done

if [ "$HELX_DEBUG" == true ]
then
  set -x
  HELM_DEBUG="--debug"
fi

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
TIMESTAMP=`date "+%Y%m%d%H%M"`

NAMESPACE=${NAMESPACE-"default"}
PROJECT=${PROJECT-"A_GOOGLE_PROJECT_ID"}
REGION=${REGION-"us-east1"}
ZONE_EXTENSION=${ZONE_EXTENSION-b}
AVAILABILITY_ZONE=${AVAILABILITY_ZONE-${REGION}-${ZONE_EXTENSION}}
ENVIRONMENT=${ENVIRONMENT-"dev"}
CLUSTER_NAME=${CLUSTER_NAME-"${USER}-cluster"}
PV_PREFIX=${PV_PREFIX-"$NAMESPACE-"}
DISK_PREFIX=${DISK_PREFIX-"${CLUSTER_NAME}-${PV_PREFIX}"}
HELXPLATFORM_HOME=${HELXPLATFORM_HOME-"$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../.."}
HELX_DEVOPS_HOME=${HELX_DEVOPS_HOME-"${HELXPLATFORM_HOME}/devops"}
GKE_DEPLOYMENT=${GKE_DEPLOYMENT-true}
SECRET_FILENAME_SUFFIX=${SECRET_FILENAME_SUFFIX-"-${CLUSTER_NAME}-${NAMESPACE}"}
DEPLOY_LOG_DIR=${DEPLOY_LOG_DIR-"${HELXPLATFORM_HOME}"}
DEPLOY_LOG=${DEPLOY_LOG-"${DEPLOY_LOG_DIR}/deploy-log-${CLUSTER_NAME}-${NAMESPACE}-$TIMESTAMP.txt"}

# Set DYNAMIC_NFSCP_DEPLOYMENT to false if NFS storage is not available (GKE).
DYNAMIC_NFSCP_DEPLOYMENT=${DYNAMIC_NFSCP_DEPLOYMENT-false}
DYNAMIC_NFSCP_DEPLOYMENT_EXISTS=${DYNAMIC_NFSCP_DEPLOYMENT_EXISTS-false}

DYNAMIC_NFSSP_DEPLOYMENT=${DYNAMIC_NFSSP_DEPLOYMENT-false}
NFSSP_NAME=${NFSSP_NAME-"${DISK_PREFIX}nfssp"}
# NFSSP persistent storage does not work on NFS storage.
NFSSP_PERSISTENCE_ENABLED=${NFSSP_PERSISTENCE_ENABLED-false}
NFSSP_PERSISTENCE_SIZE=${NFSSP_PERSISTENCE_SIZE-"200Gi"}
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
fi
if $DYNAMIC_NFSSP_DEPLOYMENT; then
  NFSP_STORAGECLASS=$NFSSP_STORAGECLASS
fi

GCE_DYN_STORAGE_PV_STORAGE=$NFSSP_PERSISTENCE_SIZE
GCE_DYN_STORAGE_PD_NAME="${NFSSP_NAME}"
GCE_DYN_STORAGE_PV_NAME="${GCE_DYN_STORAGE_PD_NAME}-nfs-server-provisioner"
GCE_DYN_STORAGE_CLAIMREF="data-$GCE_DYN_STORAGE_PV_NAME-0"

CREATE_STATIC_PV_STORAGE=${CREATE_STATIC_PV_STORAGE-false}

GCE_NFS_SERVER_DISK=${GCE_NFS_SERVER_DISK-"${DISK_PREFIX}stdnfs-disk"}
GCE_NFS_SERVER_DISK_DELETE_W_APP=${GCE_NFS_SERVER_DISK_DELETE_W_APP-false}
GCE_NFS_SERVER_STORAGE=${GCE_NFS_SERVER_STORAGE-"200Gi"}
GCE_NFS_SERVER_HELM_RELEASE=${GCE_NFS_SERVER_HELM_RELEASE-"nfs-server"}

NFS_CLNT_PV_NFS_PATH=${NFS_CLNT_PV_NFS_PATH-"/"}
NFS_CLNT_PV_NFS_SRVR=${NFS_CLNT_PV_NFS_SRVR-"nfs-server.$NAMESPACE.svc.cluster.local"}
NFS_CLNT_PV_NAME=${NFS_CLNT_PV_NAME-"${PV_PREFIX}stdnfs-pv"}
NFS_CLNT_PVC_NAME=${NFS_CLNT_PVC_NAME-"stdnfs"}
NFS_CLNT_STORAGE_SIZE=${NFS_CLNT_STORAGE_SIZE-$GCE_NFS_SERVER_STORAGE}
NFS_CLNT_STORAGECLASS=${NFS_CLNT_STORAGECLASS-"stdnfs-sc"}

NEXTFLOW_PVC=${NEXTFLOW_PVC-$NFS_CLNT_PVC_NAME}
NEXTFLOW_PV_STORAGE_SIZE=${NEXTFLOW_PV_STORAGE_SIZE-$NFS_CLNT_STORAGE_SIZE}
NEXTFLOW_PV_ACCESSMODE=${NEXTFLOW_PV_ACCESSMODE-"ReadWriteMany"}
NEXTFLOW_NFS_SERVER=${NEXTFLOW_NFS_SERVER-$NFS_CLNT_PV_NFS_SRVR}
NEXTFLOW_NFS_PATH=${NEXTFLOW_NFS_PATH-"/nextflow"}
NEXTFLOW_PV_STORAGECLASS=${NEXTFLOW_PV_STORAGECLASS-"${PV_PREFIX}nextflow-sc"}
NEXTFLOW_PV_NAME=${NEXTFLOW_PV_NAME-"${PV_PREFIX}nextflow-pv"}

AMBASSADOR_HELM_DIR=${AMBASSADOR_HELM_DIR-"$HELX_DEVOPS_HOME/helx/charts/ambassador"}
AMBASSADOR_HELM_RELEASE=${AMBASSADOR_HELM_RELEASE-"ambassador"}
AMBASSADOR_RUNASUSER=${AMBASSADOR_RUNASUSER-""}
AMBASSADOR_RUNASGROUP=${AMBASSADOR_RUNASGROUP-""}
AMBASSADOR_FSGROUP=${AMBASSADOR_FSGROUP-""}
AMBASSADOR_ROLE_INGRESSES=${AMBASSADOR_ROLE_INGRESSES-""}
USE_CLUSTER_ROLES=${USE_CLUSTER_ROLES-false}

NGINX_HELM_DIR=${NGINX_HELM_DIR="$HELX_DEVOPS_HOME/helx/charts/nginx"}
NGINX_HELM_RELEASE=${NGINX_HELM_RELEASE-"nginx-revproxy"}
NGINX_IMAGE_TAG=${NGINX_IMAGE_TAG-""}
NGINX_SERVERNAME=${NGINX_SERVERNAME-"helx.helx-dev.renci.org"}
NGINX_IP=${NGINX_IP-""}
NGINX_TLS_SECRET=${NGINX_TLS_SECRET-""}
NGINX_TLS_KEY=${NGINX_TLS_KEY-""}
NGINX_TLS_CRT=${NGINX_TLS_CRT-""}
NGINX_TLS_CA_CRT=${NGINX_TLS_CA_CRT-""}
NGINX_SERVICE_TYPE=${NGINX_SERVICE_TYPE-"LoadBalancer"}
NGINX_SERVICE_HTTP_PORT=${NGINX_SERVICE_HTTP_PORT-"80"}
NGINX_SERVICE_HTTPS_PORT=${NGINX_SERVICE_HTTPS_PORT-"443"}
NGINX_TARGET_HTTP_PORT=${NGINX_TARGET_HTTP_PORT-"8080"}
NGINX_TARGET_HTTPS_PORT=${NGINX_TARGET_HTTPS_PORT-"8443"}
NGINX_SERVICE_NODEPORT=${NGINX_SERVICE_NODEPORT-""}
NGINX_INGRESS_HOST=${NGINX_INGRESS_HOST-""}
NGINX_INGRESS_CLASS=${NGINX_INGRESS_CLASS-""}
# Set NGINX_INGRESS_TRAEFIK_ROUTER_TLS to "" to set it to "" in ingress YAML.
# Leave unset to not include the key/value pair in the ingress YAML.
# NGINX_INGRESS_TRAEFIK_ROUTER_TLS=${NGINX_INGRESS_TRAEFIK_ROUTER_TLS-""}
NGINX_VAR_STORAGE_CLAIMNAME=${NGINX_VAR_STORAGE_CLAIMNAME-""}
NGINX_VAR_STORAGE_EXISTING_CLAIM=${NGINX_VAR_STORAGE_EXISTING_CLAIM-""}
NGINX_VAR_STORAGE_SIZE=${NGINX_VAR_STORAGE_SIZE-""}
NGINX_VAR_STORAGE_CLASS=${NGINX_VAR_STORAGE_CLASS-""}
NGINX_RESTARTR_API=${NGINX_RESTARTR_API-false}
NGINX_HTTP_HOST=${NGINX_HTTP_HOST-false}

HELM=${HELM-helm}
HELM_DEBUG=${HELM_DEBUG-""}
COMMONSSHARE_HELM_RELEASE=${COMMONSSHARE_HELM_RELEASE-"commonsshare"}
COMMONSSHARE_DEPLOYMENT=${COMMONSSHARE_DEPLOYMENT-false}
CAT_HELM_DIR=${CAT_HELM_DIR-"${HELX_DEVOPS_HOME}/helx"}
CAT_USER_STORAGE_NAME=${CAT_USER_STORAGE_NAME-"stdnfs"}
# CAT_PD_NAME=${CAT_PD_NAME-"${PV_PREFIX}$CAT_USER_STORAGE_NAME-disk"}
CAT_PV_NAME=${CAT_PV_NAME-"${PV_PREFIX}$CAT_USER_STORAGE_NAME-pv"}
CAT_NFS_SERVER=${CAT_NFS_SERVER-"$NFSCP_SERVER"}
CAT_NFS_PATH=${CAT_NFS_PATH-"/sfdnfs"}
CAT_PV_STORAGE_SIZE=${CAT_PV_STORAGE_SIZE-"10Gi"} # For use with non-GKE environments.
CAT_PVC_STORAGE=${CAT_PVC_STORAGE-"10Gi"}
CAT_PV_ACCESSMODE=${CAT_PV_ACCESSMODE-"ReadWriteMany"}
CAT_PVC_ACCESSMODE=${CAT_PVC_ACCESSMODE-"ReadWriteMany"}

APPSTORE_HELM_RELEASE=${APPSTORE_HELM_RELEASE-"appstore"}
APPSTORE_RUNASUSER=${APPSTORE_RUNASUSER-""}
APPSTORE_RUNASGROUP=${APPSTORE_RUNASGROUP-""}
APPSTORE_FSGROUP=${APPSTORE_FSGROUP-""}
APPSTORE_DJANGO_USERNAME=${APPSTORE_DJANGO_USERNAME-"admin"}
# Set APPSTORE_DJANGO_PASSWORD to something other than "" or it will be assigned randomly.
APPSTORE_DJANGO_PASSWORD=${APPSTORE_DJANGO_PASSWORD-""}
APPSTORE_OAUTH_PD_NAME=${APPSTORE_OAUTH_PD_NAME-"${DISK_PREFIX}appstore-oauth-disk"}
APPSTORE_OAUTH_PD_DELETE_W_APP=${APPSTORE_OAUTH_PD_DELETE_W_APP-false}
APPSTORE_OAUTH_PV_NAME=${APPSTORE_OAUTH_PV_NAME-"${PV_PREFIX}appstore-oauth-pv"}
# Define APPSTORE_OAUTH_PVC to use a PVC for the oauth sqlite3 db storage.
APPSTORE_OAUTH_PVC=${APPSTORE_OAUTH_PVC-"appstore-oauth-pvc"}
APPSTORE_OAUTH_PVC_STORAGE=${APPSTORE_OAUTH_PVC_STORAGE-"100Mi"}
if [ $CREATE_STATIC_PV_STORAGE == true ]
then
  APPSTORE_OAUTH_PV_STORAGECLASS=${APPSTORE_OAUTH_PV_STORAGECLASS-"${PV_PREFIX}appstore-oauth-sc"}
  APPSTORE_OAUTH_PVC_USE_EXISTING=${APPSTORE_OAUTH_PVC_USE_EXISTING-true}
else
  # Use cluster default stoageclass.
  APPSTORE_OAUTH_PV_STORAGECLASS=${APPSTORE_OAUTH_PV_STORAGECLASS-""}
  APPSTORE_OAUTH_PVC_USE_EXISTING=${APPSTORE_OAUTH_PVC_USE_EXISTING-false}
fi
APPSTORE_OAUTH_NFS_SERVER=${APPSTORE_OAUTH_NFS_SERVER-$CAT_NFS_SERVER}
APPSTORE_OAUTH_NFS_PATH=${APPSTORE_OAUTH_NFS_PATH-""}
APPSTORE_OAUTH_PV_STORAGE_SIZE=${APPSTORE_OAUTH_PV_STORAGE_SIZE-"10Gi"}
APPSTORE_OAUTH_PV_ACCESSMODE=${APPSTORE_OAUTH_PV_ACCESSMODE-"ReadWriteOnce"}
APPSTORE_IMAGE_TAG=${APPSTORE_IMAGE_TAG-""}
APPSTORE_DJANGO_SETTINGS=${APPSTORE_DJANGO_SETTINGS-""}
APPSTORE_IMAGE_PULL_SECRETS=${APPSTORE_IMAGE_PULL_SECRETS-""}
APPSTORE_WITH_AMBASSADOR=${APPSTORE_WITH_AMBASSADOR-true}
APPSTORE_SAML2_AUTH_ASSERTION_URL=${APPSTORE_SAML2_AUTH_ASSERTION_URL-""}
APPSTORE_SAML2_AUTH_ENTITY_ID=${APPSTORE_SAML2_AUTH_ENTITY_ID-""}
APPSTORE_STORAGE_CLAIMNAME=${APPSTORE_STORAGE_CLAIMNAME-""}
APPSTORE_ACCOUNT_DEFAULT_HTTP_PROTOCOL=${APPSTORE_ACCOUNT_DEFAULT_HTTP_PROTOCOL-"https"}
export DICOMGH_GOOGLE_CLIENT_ID=${DICOMGH_GOOGLE_CLIENT_ID-""}
AUTHORIZED_USERS=${AUTHORIZED_USERS-""}
REMOVE_AUTHORIZED_USERS=${REMOVE_AUTHORIZED_USERS-""}

TYCHO_HELM_RELEASE=${TYCHO_HELM_RELEASE-"tycho-api"}
TYCHO_API_SERVICE_TYPE=${TYCHO_API_SERVICE_TYPE-""}
TYCHO_API_IMAGE_TAG=${TYCHO_API_IMAGE_TAG-""}
TYCHO_USE_ROLE=${TYCHO_USE_ROLE-""}
TYCHO_STDNFS_PVC=${TYCHO_STDNFS_PVC-""}
TYCHO_CREATE_HOME_DIRS=${TYCHO_CREATE_HOME_DIRS-""}
TYCHO_RUNASROOT=${TYCHO_RUNASROOT-""}
TYCHO_PARENT_DIR=${TYCHO_PARENT_DIR-""} # Chart default is "/home".
TYCHO_SUBPATH_DIR=${TYCHO_SUBPATH_DIR-""} # Chart default is null, which uses $USER.
TYCHO_SHARED_DIR=${TYCHO_SHARED_DIR-""} # Chart default is "shared".

ELASTIC_PVC_STORAGE=${ELASTIC_PVC_STORAGE-"10Gi"}
# Set X_STORAGECLASS to "" to use the default storage class.
ELASTIC_STORAGECLASS=${ELASTIC_STORAGECLASS-$NFSP_STORAGECLASS}
ELASTICSEARCH_PRIVILEGED_SECURITY_CONTEXT=${ELASTICSEARCH_PRIVILEGED_SECURITY_CONTEXT-"true"}
ELASTICSEARCH_REQUESTS_MEMORY=${ELASTICSEARCH_REQUESTS_MEMORY-"200Mi"}
ELASTICSEARCH_LIMITS_MEMORY=${ELASTICSEARCH_LIMITS_MEMORY-"512Mi"}
ES_JAVA_OPTS=${ES_JAVA_OPTS-"-Xms150m -Xmx150m -XX:-AssumeMP"}
COMMONSSHARE_DB_STORAGECLASS=${COMMONSSHARE_DB_STORAGECLASS-$NFSP_STORAGECLASS}

# This is temporary until we figure out something to use to encrypt secret
# files, like git-crypt.  ToDo: Also add something like this for appstore.
HYDROSHARE_SECRET_SRC_FILE=${HYDROSHARE_SECRET_SRC_FILE-"$HELXPLATFORM_HOME/secrets/hydroshare-secret.yaml"}
HYDROSHARE_SECRET_DST_FILE=${HYDROSHARE_SECRET_DST_FILE-"$CAT_HELM_DIR/charts/commonsshare/templates/hydroshare-secret.yaml"}

NFSRODS_HELM_RELEASE=${NFSRODS_HELM_RELEASE-"nfsrods"}
NFSRODS_HELM_DIR=${NFSRODS_HELM_DIR-"$HELX_DEVOPS_HOME/helx/charts/nfsrods"}
NFSRODS_PV_NAME=${NFSRODS_PV_NAME-"${PV_PREFIX}$NFSRODS_HELM_RELEASE-pv"}
NFSRODS_PV_STORAGE_SIZE=${NFSRODS_PV_STORAGE_SIZE-"100Gi"}
NFSRODS_PV_STORAGECLASS=${NFSRODS_PV_STORAGECLASS-"${PV_PREFIX}$NFSRODS_HELM_RELEASE-sc"}
# ToDo: Pull this IP from from the service after it's created and use that to
# create the PVC.
NFSRODS_PV_NFS_SERVER_IP=${NFSRODS_PV_NFS_SERVER_IP-"10.233.58.200"}
NFSRODS_PV_NFS_PATH=${NFSRODS_PV_NFS_PATH-"/"}
NFSRODS_PV_ACCESSMODE=${NFSRODS_PV_ACCESSMODE-"ReadWriteMany"}
NFSRODS_PVC_CLAIMNAME=${NFSRODS_PVC_CLAIMNAME-"$NFSRODS_HELM_RELEASE"}
NFSRODS_PVC_STORAGE_SIZE=${NFSRODS_PVC_STORAGE_SIZE-"10Gi"}
NFSRODS_FOR_USER_DATA=${NFSRODS_FOR_USER_DATA-false}
NFSRODS_CONFIG_PV_NAME=${NFSRODS_CONFIG_PV_NAME-"${PV_PREFIX}$NFSRODS_HELM_RELEASE-config-pv"}
NFSRODS_CONFIG_CLAIMNAME=${NFSRODS_CONFIG_CLAIMNAME-"$NFSRODS_HELM_RELEASE-config-pvc"}
NFSRODS_CONFIG_NFS_SERVER=${NFSRODS_CONFIG_NFS_SERVER-""}
NFSRODS_CONFIG_NFS_PATH=${NFSRODS_CONFIG_NFS_PATH-""}
NFSRODS_CONFIG_PV_STORAGECLASS=${NFSRODS_CONFIG_PV_STORAGECLASS-"${PV_PREFIX}$NFSRODS_HELM_RELEASE-config-sc"}
NFSRODS_CONFIG_PV_STORAGE_SIZE=${NFSRODS_CONFIG_PV_STORAGE_SIZE-"10Mi"}
NFSRODS_CONFIG_PV_ACCESSMODE=${NFSRODS_CONFIG_PV_ACCESSMODE-"ReadWriteMany"}

USE_NFS_PVS=${USE_NFS_PVS-false}

RESTARTR_DEPLOYMENT=${RESTARTR_DEPLOYMENT-false}
RESTARTR_ROOT=${RESTARTR_ROOT-"$HELXPLATFORM_HOME/restartr"}
RESTARTR_HELM_DIR=${RESTARTR_HELM_DIR-"$RESTARTR_ROOT/kubernetes/helm"}
RESTARTR_IMAGE_TAG=${RESTARTR_IMAGE_TAG-""}
RESTARTR_HELM_RELEASE=${RESTARTR_HELM_RELEASE-"restartr"}
RESTARTR_API_REQUEST_CPU=${RESTARTR_API_REQUEST_CPU-"0.25"}
RESTARTR_API_REQUEST_MEMORY=${RESTARTR_API_REQUEST_MEMORY-"200Mi"}
RESTARTR_API_LIMIT_CPU=${RESTARTR_API_LIMIT_CPU-"0.4"}
RESTARTR_API_LIMIT_MEMORY=${RESTARTR_API_LIMIT_MEMORY-"256Mi"}
RESTARTR_MONGO_REQUEST_CPU=${RESTARTR_MONGO_REQUEST_CPU-"0.25"}
RESTARTR_MONGO_REQUEST_MEMORY=${RESTARTR_MONGO_REQUEST_MEMORY-"200Mi"}
RESTARTR_MONGO_LIMIT_CPU=${RESTARTR_MONGO_LIMIT_CPU-"0.4"}
RESTARTR_MONGO_LIMIT_MEMORY=${RESTARTR_MONGO_LIMIT_MEMORY-"512Mi"}
RESTARTR_MONGO_ADMIN_USERNAME=${RESTARTR_MONGO_ADMIN_USERNAME-"admin"}
RESTARTR_MONGO_ADMIN_PASSWORD=${RESTARTR_MONGO_ADMIN_PASSWORD-""}
if [ "$RESTARTR_DEPLOYMENT" == true ]
then
  if [ -z ${RESTARTR_MONGO_ADMIN_PASSWORD+x} ]
  then
    RESTARTR_MONGO_ADMIN_PASSWORD=`random-string 20`
    echo "RESTARTR_MONGO_ADMIN_PASSWORD set to random string. Check $DEPLOY_LOG."
    echo "RESTARTR_MONGO_ADMIN_PASSWORD set to random string." >> $DEPLOY_LOG
    echo "DATE: `date`" >> $DEPLOY_LOG
    echo "RESTARTR_MONGO_ADMIN_PASSWORD: $RESTARTR_MONGO_ADMIN_PASSWORD" >> $DEPLOY_LOG
  fi
fi

EFK_NAMESPACE=${EFK_NAMESPACE-"logging"}
EFK_HELM_RELEASE=${EFK_HELM_RELEASE-"efk"}
# EFK_VERSION_ARG=${EFK_VERSION_ARG-""}
EFK_VERSION_ARG=${EFK_VERSION_ARG-"--version=v2.0.0"}
# EFK_VERSION_ARG="--version=v2.0.0"
# EFK_VERSION_ARG="--version=v2.0.1"

# Some commands need to be given time to execute after they are run before
# running other related commands (like deleting a PV then deleting the related
# disk).
KUBE_WAIT_TIME=${KUBE_WAIT_TIME-30}

DUG_API=${DUG_API-false}
# The Dug API is currently served directly from Ambassador and bypasses Nginx.
# So DUG_API_WITH_NGINX should be set to false unless we want to disable the
# Ambassador annotations in the Dug Helm chart.
DUG_API_WITH_NGINX=${DUG_API_WITH_NGINX-false}
DUG_HELM_RELEASE=${DUG_HELM_RELEASE-"dug"}
DUG_HELM_DIR=${DUG_HELM_DIR-"$DUG_HOME/devops/helx/charts/dug"}
DUG_ES_NFS_SERVER=${DUG_ES_NFS_SERVER-$CAT_NFS_SERVER}
DUG_ES_NFS_PATH=${DUG_ES_NFS_PATH-"/dug-elasticsearch"}
if [ $CREATE_STATIC_PV_STORAGE == true ]
then
  DUG_ES_PV_STORAGECLASS=${DUG_ES_PV_STORAGECLASS-""}
  DUG_NEO4J_PV_STORAGECLASS=${DUG_NEO4J_PV_STORAGECLASS-"${PV_PREFIX}dug-neo4j-sc"}
  DUG_REDIS_PV_STORAGECLASS=${DUG_REDIS_PV_STORAGECLASS-"${PV_PREFIX}dug-redis-sc"}
  DUG_CREATE_PVCS=${DUG_CREATE_PVCS-false}
else
  DUG_ES_PV_STORAGECLASS=${DUG_ES_PV_STORAGECLASS-""}
  DUG_NEO4J_PV_STORAGECLASS=${DUG_NEO4J_PV_STORAGECLASS-""}
  DUG_REDIS_PV_STORAGECLASS=${DUG_REDIS_PV_STORAGECLASS-""}
  DUG_CREATE_PVCS=${DUG_CREATE_PVCS-true}
fi
DUG_ES_DELETE_STORAGE=${DUG_ES_DELETE_STORAGE-false}
DUG_ES_APP_NAME=${DUG_ES_APP_NAME-"dug-elasticsearch"}
DUG_ES_XMS=${DUG_ES_XMS-""} # initial memory allocation pool for JVM
DUG_ES_XMX=${DUG_ES_XMX-""} # maximum memory allocation pool for JVM
DUG_NEO4J_PD_NAME=${DUG_NEO4J_PD_NAME-"${DISK_PREFIX}dug-neo4j-disk"}
DUG_NEO4J_PD_DELETE_W_APP=${DUG_NEO4J_PD_DELETE_W_APP-false}
DUG_NEO4J_PVC=${DUG_NEO4J_PVC-"dug-neo4j-pvc"}
DUG_NEO4J_PV_STORAGE_SIZE=${DUG_NEO4J_PV_STORAGE_SIZE-"10G"}
DUG_NEO4J_PV_ACCESSMODE=${DUG_NEO4J_PV_ACCESSMODE-"ReadWriteMany"}
DUG_NEO4J_NFS_SERVER=${DUG_NEO4J_NFS_SERVER-$CAT_NFS_SERVER}
DUG_NEO4J_NFS_PATH=${DUG_NEO4J_NFS_PATH-"/dug-neo4j"}
DUG_NEO4J_PV_NAME=${DUG_NEO4J_PV_NAME-"${PV_PREFIX}dug-neo4j-pv"}
DUG_NEO4J_APP_NAME=${DUG_NEO4J_APP_NAME-"dug-neo4j"}
DUG_REDIS_PD_NAME=${DUG_REDIS_PD_NAME-"${DISK_PREFIX}dug-redis-disk"}
DUG_REDIS_PD_DELETE_W_APP=${DUG_REDIS_PD_DELETE_W_APP-false}
DUG_REDIS_PVC=${DUG_REDIS_PVC-"dug-redis-pvc"}
DUG_REDIS_PV_STORAGE_SIZE=${DUG_REDIS_PV_STORAGE_SIZE-"10G"}
DUG_REDIS_PV_ACCESSMODE=${DUG_REDIS_PV_ACCESSMODE-"ReadWriteMany"}
DUG_REDIS_NFS_SERVER=${DUG_REDIS_NFS_SERVER-$CAT_NFS_SERVER}
DUG_REDIS_NFS_PATH=${DUG_REDIS_NFS_PATH-"/dug-redis"}
DUG_REDIS_PV_NAME=${DUG_REDIS_PV_NAME-"${PV_PREFIX}dug-redis-pv"}
DUG_REDIS_APP_NAME=${DUG_REDIS_APP_NAME-"dug-redis"}
DUG_WEB_APP_NAME=${DUG_WEB_APP_NAME-"dug-web"}
DUG_WEB_IMAGE_TAG=${DUG_WEB_IMAGE_TAG-""}
DUG_SC_APP_NAME=${DUG_SC_APP_NAME-"dug-search-client"}
DUG_SC_IMAGE_TAG=${DUG_SC_IMAGE_TAG-""}
DUG_NBOOST_APP_NAME=${DUG_NBOOST_APP_NAME-"dug-nboost"}

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
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" == true ]; then
    if [ "$DYNAMIC_NFSCP_DEPLOYMENT_EXISTS" == false ]; then
      echo "Deploying NFS Client Provisioner for Dynamic PVCs"
      $HELM -n $NAMESPACE upgrade --install \
                   --set nfs.server=$NFSCP_SERVER \
                   --set nfs.path=$NFSCP_PATH \
                   --set storageClass.name=$NFSCP_STORAGECLASS \
                   $NFSCP_NAME stable/nfs-client-provisioner
    fi
  fi
  if [ "$DYNAMIC_NFSSP_DEPLOYMENT" == true ]; then
    if [ "$GKE_DEPLOYMENT" == true ]; then
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
  if [ "$DYNAMIC_NFSCP_DEPLOYMENT" == true ]; then
    echo "Deleting NFS Client Provisioner for Dynamic PVCs"
    $HELM -n $NAMESPACE delete $NFSCP_NAME
  fi
  if [ "$DYNAMIC_NFSSP_DEPLOYMENT" == true ]; then
    echo "Deleting NFS Server Provisioner for Dynamic PVCs"
    $HELM -n $NAMESPACE delete $NFSSP_NAME
    if [ "$GKE_DEPLOYMENT" == true ]; then
      deleteGKEPVC $GCE_DYN_STORAGE_CLAIMREF
      deleteGKEPV $GCE_DYN_STORAGE_PV_NAME
      echo "Pausing for PV to be deleted fully."
      sleep $KUBE_WAIT_TIME
      deleteGCEDisk $GCE_DYN_STORAGE_PD_NAME
    fi
  fi
}


function deployELK(){
   echo "# deploying ELK"
   export PVC_STORAGE_CLASS_NAME=$ELASTIC_STORAGECLASS
   export ELASTIC_PVC_STORAGE
   export ELASTICSEARCH_PRIVILEGED_SECURITY_CONTEXT
   export ELASTICSEARCH_REQUESTS_MEMORY
   export ELASTICSEARCH_LIMITS_MEMORY
   export ES_JAVA_OPTS
   cat $HELX_DEVOPS_HOME/elasticsearch/elasticsearch-template.yaml | envsubst | \
          kubectl apply -n $NAMESPACE -f -
   kubectl apply -n $NAMESPACE -R -f $HELX_DEVOPS_HOME/elasticsearch/es-service.yaml
   kubectl apply -n $NAMESPACE -R -f $HELX_DEVOPS_HOME/kibana/
   kubectl apply -n $NAMESPACE -R -f $HELX_DEVOPS_HOME/logstash/
   echo "# end deploying ELK"
}


function deleteELK(){
   echo "# deleting ELK"
   # delete ELK
   kubectl delete -n $NAMESPACE -R -f $HELX_DEVOPS_HOME/elasticsearch/es-service.yaml
   kubectl delete -n $NAMESPACE -R -f $HELX_DEVOPS_HOME/logstash/
   kubectl delete -n $NAMESPACE -R -f $HELX_DEVOPS_HOME/kibana/
   export PVC_STORAGE_CLASS_NAME=$NFSP_STORAGECLASS
   export ELASTIC_PVC_STORAGE
   cat $HELX_DEVOPS_HOME/elasticsearch/elasticsearch-template.yaml | envsubst | \
          kubectl delete -n $NAMESPACE -f -
   echo "# end deleting ELK"
}


function deployEFK(){
  kubectl create namespace $EFK_NAMESPACE
  HELM_VALUES="elasticsearch.enabled=true"
  HELM_VALUES+=",kibana.enabled=true"
  HELM_VALUES+=",logstash.enabled=false"
  HELM_VALUES+=",fluent-bit.enabled=true,fluent-bit.backend.type=es"
  HELM_VALUES+=",fluent-bit.backend.es.host=$EFK_HELM_RELEASE-elasticsearch-client"
  helm upgrade --install -n $EFK_NAMESPACE $EFK_VERSION_ARG $EFK_HELM_RELEASE stable/elastic-stack --set $HELM_VALUES
}


function deleteEFK(){
  helm -n $EFK_NAMESPACE delete $EFK_HELM_RELEASE
}


function deployNFSServer(){
   echo "# deploying NFS"

   HELM_VALUES="stdnfs.pvcName=$NFS_CLNT_PVC_NAME"
   if [ $CREATE_STATIC_PV_STORAGE == true ]
   then
     createGCEDisk $GCE_NFS_SERVER_DISK $GCE_NFS_SERVER_STORAGE
     HELM_VALUES+=",storage.gcePersistentDiskPdName=$GCE_NFS_SERVER_DISK"
   fi
   if [ ! -z "$GCE_NFS_SERVER_STORAGE" ]
   then
     HELM_VALUES+=",storage.pvcStorage=$GCE_NFS_SERVER_STORAGE"
     HELM_VALUES+=",stdnfs.pvStorage=$GCE_NFS_SERVER_STORAGE"
     HELM_VALUES+=",stdnfs.pvcStorage=$GCE_NFS_SERVER_STORAGE"
   fi
   $HELM -n $NAMESPACE upgrade --install $GCE_NFS_SERVER_HELM_RELEASE \
      $CAT_HELM_DIR/charts/nfs-server $HELM_DEBUG --logtostderr --set $HELM_VALUES

   echo "# end deploying NFS"
}


function deleteNFSServer(){
   echo "# deleting NFS"
   kubectl -n $NAMESPACE delete pvc $NFS_CLNT_PVC_NAME
   kubectl -n $NAMESPACE delete pv $NFS_CLNT_PV_NAME

   $HELM -n $NAMESPACE delete $GCE_NFS_SERVER_HELM_RELEASE

   if [ $GCE_NFS_SERVER_DISK_DELETE_W_APP == true ]; then
     if [ $CREATE_STATIC_PV_STORAGE == true ]
     then
       echo "### Deleting NFS Server Persistent disk."
       sleep $KUBE_WAIT_TIME
       deleteGCEDisk $GCE_NFS_SERVER_DISK
     fi
   else
     echo "### Not deleting NFS Server Persistent disk."
   fi
   echo "# end deleting NFS"
}


function createPVC(){
   export PVC_NAME=$1
   export PVC_STORAGE_SIZE=$2
   export PVC_ACCESSMODE=$3
   # PVC_STORAGE_CLASS_NAME can be empty.
   export PVC_STORAGE_CLASS_NAME=$4
   echo "# creating $PVC_NAME PVC"
   echo -e "
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: "${PVC_NAME}"
spec:
  storageClassName: "${PVC_STORAGE_CLASS_NAME}"
  accessModes:
   - "${PVC_ACCESSMODE}"
  resources:
    requests:
      storage: "${PVC_STORAGE_SIZE}"
" | kubectl -n $NAMESPACE create -f -
   echo "# $PVC_NAME PVC created"
}


function deletePVC(){
    export PVC_NAME=$1
    kubectl -n $NAMESPACE delete pvc $PVC_NAME
    echo "# $PVC_NAME PVC deleted"
}


function createNFSPV(){
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


function createNFSPVC(){
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


function deleteNFSPV(){
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


function deleteNFSPVC(){
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
  deployCommonsShare
  deployAppStore
  deployTycho
  echo "# end deploying CAT"
}


function deleteCAT(){
  echo "# deleting CAT"
  deleteTycho
  deleteAppStore
  deleteCommonsShare
  echo "# end deleting CAT"
}


function deployTycho(){
  echo "# deploying Tycho"
  ## Deploy Tycho-API
  HELM_VALUES="serviceAccount.name=${PV_PREFIX}tycho-api"
  if [ "$TYCHO_USE_ROLE" == false ]
  then
   HELM_VALUES+=",useRole=false"
  fi
  if [ "$USE_CLUSTER_ROLES" == true ]
  then
    HELM_VALUES+=",useClusterRole=true"
  fi
  if [ ! -z "$TYCHO_API_SERVICE_TYPE" ]
  then
    HELM_VALUES+=",service.type=$TYCHO_API_SERVICE_TYPE"
  fi
  if [ ! -z "$TYCHO_API_IMAGE_TAG" ]
  then
    HELM_VALUES+=",image.tag=$TYCHO_API_IMAGE_TAG"
  fi
  if [ ! -z "$TYCHO_STDNFS_PVC" ]
  then
    HELM_VALUES+=",stdnfsPvc=$TYCHO_STDNFS_PVC"
  fi
  if [ ! -z "$TYCHO_CREATE_HOME_DIRS" ]
  then
    HELM_VALUES+=",createHomeDirs=$TYCHO_CREATE_HOME_DIRS"
  fi
  if [ ! -z "$TYCHO_RUNASROOT" ]
  then
    HELM_VALUES+=",runAsRoot=$TYCHO_RUNASROOT"
  fi
  if [ ! -z "$TYCHO_PARENT_DIR" ]
  then
    HELM_VALUES+=",parent_dir=$TYCHO_PARENT_DIR"
  fi
  if [ ! -z "$TYCHO_SUBPATH_DIR" ]
  then
    HELM_VALUES+=",subpath_dir=$TYCHO_SUBPATH_DIR"
  fi
  if [ ! -z "$TYCHO_SHARED_DIR" ]
  then
    HELM_VALUES+=",shared_dir=$TYCHO_SHARED_DIR"
  fi
  $HELM -n $NAMESPACE upgrade --install $TYCHO_HELM_RELEASE \
     $CAT_HELM_DIR/charts/tycho-api $HELM_DEBUG --logtostderr --set $HELM_VALUES
   echo "# end deploying Tycho"
}


function deleteTycho(){
  echo "# deleting Tycho"
  $HELM -n $NAMESPACE delete $TYCHO_HELM_RELEASE
  echo "# end deleting Tycho"
}


function createAppStoreData(){
  echo "# creating AppStore data"
  if [ "$GKE_DEPLOYMENT" == true ]
  then
    createGCEDisk $APPSTORE_OAUTH_PD_NAME $APPSTORE_OAUTH_PV_STORAGE_SIZE
    createGKEPV $APPSTORE_OAUTH_PD_NAME $APPSTORE_OAUTH_PV_NAME \
        $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PVC
    createGKEPVC $APPSTORE_OAUTH_PVC $APPSTORE_OAUTH_PV_STORAGE_SIZE
  elif [ "$USE_NFS_PVS" == true ]
  then
    createNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
        $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
        $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
    createPVC $APPSTORE_OAUTH_PVC $APPSTORE_OAUTH_PVC_STORAGE \
         $APPSTORE_OAUTH_PV_ACCESSMODE $APPSTORE_OAUTH_PV_STORAGECLASS
  else
    createPVC $APPSTORE_OAUTH_PVC $APPSTORE_OAUTH_PVC_STORAGE \
         $APPSTORE_OAUTH_PV_ACCESSMODE $APPSTORE_OAUTH_PV_STORAGECLASS
  fi
}


function deployAppStore(){
  if [ $CREATE_STATIC_PV_STORAGE == true ]
  then
    createAppStoreData
  fi
  HELM_VALUES="ACCOUNT_DEFAULT_HTTP_PROTOCOL=$APPSTORE_ACCOUNT_DEFAULT_HTTP_PROTOCOL"
  ## Deploy AppStore
  if [ ! -z "$APPSTORE_OAUTH_PVC" ]
  then
   HELM_VALUES+=",oauth.claimName=$APPSTORE_OAUTH_PVC"
  fi
  # check if variable is set (even if "")
  if [ ! -z ${APPSTORE_OAUTH_PV_STORAGECLASS+x} ]
  then
   HELM_VALUES+=",oauth.storageClass=$APPSTORE_OAUTH_PV_STORAGECLASS"
  fi
  if [ ! -z "$APPSTORE_OAUTH_PVC_USE_EXISTING" ]
  then
   HELM_VALUES+=",oauth.existingClaim=$APPSTORE_OAUTH_PVC_USE_EXISTING"
  fi
  if [ ! -z "$APPSTORE_IMAGE_TAG" ]
  then
   HELM_VALUES+=",image.tag=$APPSTORE_IMAGE_TAG"
  fi
  if [ ! -z "$APPSTORE_IMAGE_PULL_SECRETS" ]
  then
   HELM_VALUES+=",imagePullSecrets=$APPSTORE_IMAGE_PULL_SECRETS"
  fi
  if [ ! -z "$APPSTORE_DJANGO_SETTINGS" ]
  then
   HELM_VALUES+=",djangoSettings=$APPSTORE_DJANGO_SETTINGS"
  fi
  if [ "$APPSTORE_WITH_AMBASSADOR" == false ]
  then
   HELM_VALUES+=",ambassador.flag=false"
  fi
  if [ ! -z "$APPSTORE_RUNASUSER" ]
  then
   HELM_VALUES+=",securityContext.runAsUser=$APPSTORE_RUNASUSER"
  fi
  if [ ! -z "$APPSTORE_RUNASGROUP" ]
  then
   HELM_VALUES+=",securityContext.runAsGroup=$APPSTORE_RUNASGROUP"
  fi
  if [ ! -z "$APPSTORE_FSGROUP" ]
  then
   HELM_VALUES+=",securityContext.fsGroup=$APPSTORE_FSGROUP"
  fi
  if [ ! -z "$APPSTORE_SAML2_AUTH_ASSERTION_URL" ]
  then
   HELM_VALUES+=",django.saml2auth.ASSERTION_URL=$APPSTORE_SAML2_AUTH_ASSERTION_URL"
  fi
  if [ ! -z "$APPSTORE_SAML2_AUTH_ENTITY_ID" ]
  then
   HELM_VALUES+=",django.saml2auth.ENTITY_ID=$APPSTORE_SAML2_AUTH_ENTITY_ID"
  fi
  if [ ! -z "$APPSTORE_ALLOW_DJANGO_LOGIN" ]
  then
   HELM_VALUES+=",django.ALLOW_DJANGO_LOGIN=$APPSTORE_ALLOW_DJANGO_LOGIN"
  fi
  if [ ! -z "$APPSTORE_ALLOW_SAML_LOGIN" ]
  then
   HELM_VALUES+=",django.ALLOW_SAML_LOGIN=$APPSTORE_ALLOW_SAML_LOGIN"
  fi
  if [ ! -z "$APPSTORE_STORAGE_CLAIMNAME" ]
  then
   HELM_VALUES+=",appStorage.claimName=$APPSTORE_STORAGE_CLAIMNAME"
  fi

  if [ -z "$APPSTORE_DJANGO_PASSWORD" ]
  then
    APPSTORE_DJANGO_PASSWORD=`random-string 20`
    echo "APPSTORE_DJANGO_PASSWORD set to random string.  Check $DEPLOY_LOG."
    echo "APPSTORE_DJANGO_PASSWORD set to random string." >> $DEPLOY_LOG
    echo "DATE: `date`" >> $DEPLOY_LOG
    echo "APPSTORE_DJANGO_PASSWORD: $APPSTORE_DJANGO_PASSWORD" >> $DEPLOY_LOG
  fi
  HELM_VALUES+=",django.APPSTORE_DJANGO_USERNAME=$APPSTORE_DJANGO_USERNAME"
  HELM_VALUES+=",django.APPSTORE_DJANGO_PASSWORD=$APPSTORE_DJANGO_PASSWORD"
  HELM_VALUES+=",django.SECRET_KEY=$SECRET_KEY"
  HELM_VALUES+=",django.EMAIL_HOST_USER=$EMAIL_HOST_USER"
  HELM_VALUES+=",django.EMAIL_HOST_PASSWORD=$EMAIL_HOST_PASSWORD"
  HELM_VALUES+=",django.oauth.OAUTH_PROVIDERS=$OAUTH_PROVIDERS"
  HELM_VALUES+=",django.oauth.GITHUB_NAME=$GITHUB_NAME"
  HELM_VALUES+=",django.oauth.GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID"
  HELM_VALUES+=",django.oauth.GITHUB_SECRET=$GITHUB_SECRET"
  HELM_VALUES+=",django.oauth.GOOGLE_NAME=$GOOGLE_NAME"
  HELM_VALUES+=",django.oauth.GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID"
  HELM_VALUES+=",django.oauth.GOOGLE_SECRET=$GOOGLE_SECRET"

  if [ ! -z "$BRAINI_RODS" ]
  then
    HELM_VALUES+=",irods.enabled=true"
    HELM_VALUES+=",irods.BRAINI_RODS=$BRAINI_RODS"
    HELM_VALUES+=",irods.NRC_MICROSCOPY_IRODS=$NRC_MICROSCOPY_IRODS"
    HELM_VALUES+=",irods.RODS_USERNAME=$RODS_USERNAME"
    HELM_VALUES+=",irods.RODS_PASSWORD=$RODS_PASSWORD"
    HELM_VALUES+=",irods.IROD_COLLECTIONS=$IROD_COLLECTIONS"
    HELM_VALUES+=",irods.IROD_ZONE=$IROD_ZONE"
  fi

  if [ ! -z "$DICOMGH_GOOGLE_CLIENT_ID" ]
  then
    HELM_VALUES+=",apps.DICOMGH_GOOGLE_CLIENT_ID=$DICOMGH_GOOGLE_CLIENT_ID"
  fi
  if [ ! -z "$AUTHORIZED_USERS" ]
  then
    HELM_VALUES+=",django.AUTHORIZED_USERS=$AUTHORIZED_USERS"
  fi
  if [ ! -z "$REMOVE_AUTHORIZED_USERS" ]
  then
    HELM_VALUES+=",django.REMOVE_AUTHORIZED_USERS=$REMOVE_AUTHORIZED_USERS"
  fi

  if [ $CREATE_STATIC_PV_STORAGE == true ]
  then
    if [ $GKE_DEPLOYMENT == false ]
    then
      HELM_VALUES+=",userStorage.createPVC=true"
      HELM_VALUES+=",userStorage.nfs.createPV=true"
      HELM_VALUES+=",userStorage.nfs.path=$CAT_NFS_PATH"
      HELM_VALUES+=",userStorage.nfs.server=$CAT_NFS_SERVER"
      HELM_VALUES+=",userStorage.storageClass=$NFS_CLNT_STORAGECLASS"
    fi
  fi
  if [ $GKE_DEPLOYMENT == false ]
  then
    HELM_VALUES+=",userStorage.createPVC=true"
  fi

  $HELM -n $NAMESPACE upgrade $APPSTORE_HELM_RELEASE \
     $CAT_HELM_DIR/charts/appstore --install $HELM_DEBUG --logtostderr --set $HELM_VALUES
  echo "# end deploying AppStore"
}


function deleteAppStore(){
  echo "# deleting AppStore"
  $HELM -n $NAMESPACE delete $APPSTORE_HELM_RELEASE
  deleteAppStoreData
  echo "# end deleting AppStore"
}

function deleteAppStoreData(){
  echo "# deleting AppStore data"
  if [ "$GKE_DEPLOYMENT" == true ]; then
    deleteGKEPVC $APPSTORE_OAUTH_PVC
    deleteGKEPV $APPSTORE_OAUTH_PV_NAME
    if [ "$APPSTORE_OAUTH_PD_DELETE_W_APP" == true ]; then
      echo "### Deleting AppStore Oauth Persistent disk."
      sleep $KUBE_WAIT_TIME
      deleteGCEDisk $APPSTORE_OAUTH_PD_NAME
    else
      echo "### Not deleting AppStore Oauth Persistent disk."
    fi
  elif [ "$USE_NFS_PVS" == true ]
  then
    if [ "$APPSTORE_OAUTH_PD_DELETE_W_APP" == true ]; then
      deletePVC $APPSTORE_OAUTH_PVC
      deleteNFSPV $APPSTORE_OAUTH_PV_NAME $APPSTORE_OAUTH_NFS_SERVER \
          $APPSTORE_OAUTH_NFS_PATH $APPSTORE_OAUTH_PV_STORAGECLASS \
          $APPSTORE_OAUTH_PV_STORAGE_SIZE $APPSTORE_OAUTH_PV_ACCESSMODE
      echo "-------------------------"
    fi
  else
    if [ "$APPSTORE_OAUTH_PD_DELETE_W_APP" == true ]; then
      echo "### Deleting AppStore Oauth PVC."
      deletePVC $APPSTORE_OAUTH_PVC
    else
      echo "### Not deleting AppStore Oauth PVC."
    fi
  fi
  echo "# end deleting AppStore Data"
}


function deployCommonsShare(){
  echo "# deploying CommonsShare"
  if [ "$COMMONSSHARE_DEPLOYMENT" == true ]
  then
    if [ -f "$HYDROSHARE_SECRET_SRC_FILE" ]
    then
     echo "copying \"$HYDROSHARE_SECRET_SRC_FILE\" to"
     echo "  \"$HYDROSHARE_SECRET_DST_FILE\""
     cp $HYDROSHARE_SECRET_SRC_FILE $HYDROSHARE_SECRET_DST_FILE
    else
     echo "Hydroshare secrets source file not found:"
     echo "  file: \"$HYDROSHARE_SECRET_SRC_FILE\""
     echo "### Not copying hydroshare secrets file. ###"
    fi
  fi

  if [ "$COMMONSSHARE_DEPLOYMENT" == true ]
  then
    ## Deploy CommonsShare
    HELM_VALUES="web.db.storageClass=$COMMONSSHARE_DB_STORAGECLASS"
    $HELM -n $NAMESPACE upgrade --install $COMMONSSHARE_HELM_RELEASE \
      $CAT_HELM_DIR/charts/commonsshare $HELM_DEBUG --logtostderr --set $HELM_VALUES
  fi
  echo "# end deploying CommonsShare"
}


function deleteCommonsShare(){
  echo "# deleting CommonsShare"
  $HELM -n $NAMESPACE delete $COMMONSSHARE_HELM_RELEASE
  echo "# end deleting CommonsShare"
}

function deployAmbassador(){
   echo "# deploying Ambassador"
   if [ "$USE_CLUSTER_ROLES" == false ]; then
     HELM_VALUES="prp.deployment=true"
     HELM_SET_ARG="--set $HELM_VALUES"
   else
     HELM_SET_ARG=""
   fi
   if [ ! -z "$AMBASSADOR_RUNASUSER" ]
   then
    HELM_VALUES+=",securityContext.runAsUser=$AMBASSADOR_RUNASUSER"
   fi
   if [ ! -z "$AMBASSADOR_RUNASGROUP" ]
   then
    HELM_VALUES+=",securityContext.runAsGroup=$AMBASSADOR_RUNASGROUP"
   fi
   if [ ! -z "$AMBASSADOR_FSGROUP" ]
   then
    HELM_VALUES+=",securityContext.fsGroup=$AMBASSADOR_FSGROUP"
   fi
   if [ ! -z "$AMBASSADOR_ROLE_INGRESSES" ]
   then
    HELM_VALUES+=",roleIngresses=$AMBASSADOR_ROLE_INGRESSES"
   fi
   if [ "$HELM_VALUES" = "" ]; then
     HELM_SET_ARG=""
   else
     HELM_SET_ARG="--set $HELM_VALUES"
   fi
   $HELM -n $NAMESPACE upgrade --install $AMBASSADOR_HELM_RELEASE $AMBASSADOR_HELM_DIR $HELM_DEBUG \
       --logtostderr $HELM_SET_ARG
   echo "# end deploying Ambassador"
}


function deleteAmbassador(){
   echo "# deleting Ambassador"
   $HELM -n $NAMESPACE delete $AMBASSADOR_HELM_RELEASE
   kubectl delete -n $NAMESPACE CustomResourceDefinition  mappings.getambassador.io
   echo "# end deleting Ambassador"
}


function deployNginxRevProxy(){
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
   if [ ! -z "${NGINX_IP}" ]
   then
     HELM_VALUES+=",service.IP=$NGINX_IP"
   fi
   HELM_VALUES+=",service.type=\"$NGINX_SERVICE_TYPE\""
   if [ ! -z "$NGINX_SERVICE_NODEPORT" ]
     then
     HELM_VALUES+=",service.nodePort=$NGINX_SERVICE_NODEPORT"
   fi
   if [ ! -z "$NGINX_SERVICE_HTTP_PORT" ]
     then
     HELM_VALUES+=",service.httpPort=$NGINX_SERVICE_HTTP_PORT"
   fi
   if [ ! -z "$NGINX_SERVICE_HTTPS_PORT" ]
     then
     HELM_VALUES+=",service.httpsPort=$NGINX_SERVICE_HTTPS_PORT"
   fi
   if [ ! -z "$NGINX_TARGET_HTTP_PORT" ]
     then
     HELM_VALUES+=",service.httpTargetPort=$NGINX_TARGET_HTTP_PORT"
   fi
   if [ ! -z "$NGINX_TARGET_HTTPS_PORT" ]
     then
     HELM_VALUES+=",service.httpsTargetPort=$NGINX_TARGET_HTTPS_PORT"
   fi
   if [ ! -z "$NGINX_TLS_SECRET" ]
   then
     HELM_VALUES+=",SSL.nginxTLSSecret=$NGINX_TLS_SECRET"
   fi
   if [ ! -z "$NGINX_INGRESS_HOST" ]
   then
     HELM_VALUES+=",ingress.host=$NGINX_INGRESS_HOST"
   fi
   if [ ! -z "$NGINX_IMAGE_TAG" ]
   then
     HELM_VALUES+=",image.tag=\"$NGINX_IMAGE_TAG\""
   fi
   if [ ! -z "$NGINX_INGRESS_CLASS" ]
   then
     HELM_VALUES+=",ingress.class=\"$NGINX_INGRESS_CLASS\""
   fi
   if [ ! -z ${NGINX_INGRESS_TRAEFIK_ROUTER_TLS+x} ]
   then
     HELM_VALUES+=",ingress.traefikRouterTls=\"$NGINX_INGRESS_TRAEFIK_ROUTER_TLS\""
   fi
   if [ ! -z "$NGINX_VAR_STORAGE_CLAIMNAME" ]
   then
    HELM_VALUES+=",varStorage.claimName=$NGINX_VAR_STORAGE_CLAIMNAME"
   fi
   if [ ! -z "$NGINX_VAR_STORAGE_EXISTING_CLAIM" ]
   then
    HELM_VALUES+=",varStorage.existingClaim=$NGINX_VAR_STORAGE_EXISTING_CLAIM"
   fi
   if [ ! -z "$NGINX_VAR_STORAGE_SIZE" ]
   then
    HELM_VALUES+=",varStorage.storageSize=$NGINX_VAR_STORAGE_SIZE"
   fi
   if [ ! -z "$NGINX_VAR_STORAGE_CLASS" ]
   then
    HELM_VALUES+=",varStorage.storageClass=$NGINX_VAR_STORAGE_CLASS"
   fi
   if [ "$NGINX_RESTARTR_API" == true ]
   then
     HELM_VALUES+=",restartrApi=$NGINX_RESTARTR_API"
   fi
   if [ "$DUG_API_WITH_NGINX" == true ]
   then
     HELM_VALUES+=",dugApi=true"
   fi
   if [ "$NGINX_HTTP_HOST" == true ]
   then
     HELM_VALUES+=",http_host=true"
   fi
   $HELM -n $NAMESPACE upgrade --install $NGINX_HELM_RELEASE $NGINX_HELM_DIR $HELM_DEBUG \
       --logtostderr --set $HELM_VALUES
   echo "# end deploying Nginx"
}


function deleteNginxRevProxy(){
  echo "# deleting Nginx"
  $HELM -n $NAMESPACE delete $NGINX_HELM_RELEASE
  if [ ! -z "$NGINX_TLS_KEY" ]
  then
   kubectl --namespace $NAMESPACE delete secret $NGINX_TLS_SECRET
  fi
  echo "# end deleting Nginx"
}


function deployNFSRODS(){
  echo "deploying NFSRODS"
  createNFSPV $NFSRODS_CONFIG_PV_NAME $NFSRODS_CONFIG_NFS_SERVER \
      $NFSRODS_CONFIG_NFS_PATH $NFSRODS_CONFIG_PV_STORAGECLASS \
      $NFSRODS_CONFIG_PV_STORAGE_SIZE $NFSRODS_CONFIG_PV_ACCESSMODE
  HELM_VALUES="config.claimName=$NFSRODS_CONFIG_CLAIMNAME"
  HELM_VALUES+=",config.storageClass=$NFSRODS_CONFIG_PV_STORAGECLASS"
  HELM_VALUES+=",service.ip=$NFSRODS_PV_NFS_SERVER_IP"
  $HELM -n $NAMESPACE upgrade --install $NFSRODS_HELM_RELEASE $NFSRODS_HELM_DIR $HELM_DEBUG \
      --logtostderr --set $HELM_VALUES
  createNFSPV $NFSRODS_PV_NAME $NFSRODS_PV_NFS_SERVER_IP \
      $NFSRODS_PV_NFS_PATH $NFSRODS_PV_STORAGECLASS \
      $NFSRODS_PV_STORAGE_SIZE $NFSRODS_PV_ACCESSMODE
  createPVC $NFSRODS_PVC_CLAIMNAME $NFSRODS_PVC_STORAGE_SIZE \
      $NFSRODS_PV_ACCESSMODE $NFSRODS_PV_STORAGECLASS
  echo "NFSRODS deployed"
}


function deleteNFSRODS(){
  echo "deleting NFSRODS"
  deletePVC $NFSRODS_PVC_CLAIMNAME
  deleteNFSPV $NFSRODS_PV_NAME $NFSRODS_PV_NFS_SERVER_IP \
      $NFSRODS_PV_NFS_PATH $NFSRODS_PV_STORAGECLASS \
      $NFSRODS_PV_STORAGE_SIZE $NFSRODS_PV_ACCESSMODE
  $HELM -n $NAMESPACE delete $NFSRODS_HELM_RELEASE
  echo "NFSRODS deleted"
}


function deleteNFSRODSData(){
  echo "deleting NFSRODS data"
  deletePVC $NFSRODS_PVC_CLAIMNAME
  deleteNFSPV $NFSRODS_CONFIG_PV_NAME $NFSRODS_CONFIG_NFS_SERVER \
      $NFSRODS_CONFIG_NFS_PATH $NFSRODS_CONFIG_PV_STORAGECLASS \
      $NFSRODS_CONFIG_PV_STORAGE_SIZE $NFSRODS_CONFIG_PV_ACCESSMODE
  echo "NFSRODS data deleted"
}


function createNextflowStorage(){
  echo "# creating storage for Nextflow"
  if [ "$GKE_DEPLOYMENT" == true ]; then
    createNFSPV $NEXTFLOW_PV_NAME $NFS_CLNT_PV_NFS_SRVR \
        $NFS_CLNT_PV_NFS_PATH $NFS_CLNT_STORAGECLASS $NEXTFLOW_PV_STORAGE_SIZE \
        $NEXTFLOW_PV_ACCESSMODE
    createNFSPVC $NEXTFLOW_PVC $NFS_CLNT_STORAGECLASS \
        $NEXTFLOW_PV_STORAGE_SIZE $NEXTFLOW_PV_ACCESSMODE
  else
    createNFSPV $NEXTFLOW_PV_NAME $NEXTFLOW_NFS_SERVER \
        $NEXTFLOW_NFS_PATH $NEXTFLOW_PV_STORAGECLASS \
        $NEXTFLOW_PV_STORAGE_SIZE $NEXTFLOW_PV_ACCESSMODE
    createPVC $NEXTFLOW_PVC $NEXTFLOW_PV_STORAGE_SIZE $NEXTFLOW_PV_ACCESSMODE \
        $NEXTFLOW_PV_STORAGECLASS
  fi
}


function deleteNextflowStorage(){
  echo "# deleting storage for Nextflow"
  if [ "$GKE_DEPLOYMENT" == true ]; then
    deleteNFSPVC $NEXTFLOW_PVC $NFS_CLNT_STORAGECLASS \
        $NEXTFLOW_PV_STORAGE_SIZE $NEXTFLOW_PV_ACCESSMODE
    deleteNFSPV $NEXTFLOW_PV_NAME $NFS_CLNT_PV_NFS_SRVR \
        $NFS_CLNT_PV_NFS_PATH $NFS_CLNT_STORAGECLASS $NEXTFLOW_PV_STORAGE_SIZE \
        $NEXTFLOW_PV_ACCESSMODE
  else
    deletePVC $NEXTFLOW_PVC
    deleteNFSPV $NEXTFLOW_PV_NAME $NEXTFLOW_NFS_SERVER \
        $NEXTFLOW_NFS_PATH $NEXTFLOW_PV_STORAGECLASS \
        $NEXTFLOW_PV_STORAGE_SIZE $NEXTFLOW_PV_ACCESSMODE
  fi
}


function restartr(){
  if [ "$1" == "deploy" ]
  then
    echo "deploying restartr"
    HELM_VALUES="api.request.cpu=$RESTARTR_API_REQUEST_CPU"
    HELM_VALUES+=",api_key=$RESTARTR_API_KEY"
    HELM_VALUES+=",api.request.memory=$RESTARTR_API_REQUEST_MEMORY"
    HELM_VALUES+=",api.limit.cpu=$RESTARTR_API_LIMIT_CPU"
    HELM_VALUES+=",api.limit.memory=$RESTARTR_API_LIMIT_MEMORY"
    HELM_VALUES+=",mongo.request.cpu=$RESTARTR_MONGO_REQUEST_CPU"
    HELM_VALUES+=",mongo.request.memory=$RESTARTR_MONGO_REQUEST_MEMORY"
    HELM_VALUES+=",mongo.limit.cpu=$RESTARTR_MONGO_LIMIT_CPU"
    HELM_VALUES+=",mongo.limit.memory=$RESTARTR_MONGO_LIMIT_MEMORY"
    HELM_VALUES+=",mongo_username=$RESTARTR_MONGO_ADMIN_USERNAME"
    HELM_VALUES+=",mongo_password=$RESTARTR_MONGO_ADMIN_PASSWORD"
    if [ ! -z "$RESTARTR_IMAGE_TAG" ]
    then
      HELM_VALUES+=",api.image_tag=$RESTARTR_IMAGE_TAG"
    fi
    $HELM -n $NAMESPACE upgrade --install $RESTARTR_HELM_RELEASE $RESTARTR_HELM_DIR $HELM_DEBUG \
        --logtostderr --set $HELM_VALUES
    echo "finished deploying restartr"
  elif [ "$1" == "delete" ]
  then
    echo "deleting restartr"
    $HELM -n $NAMESPACE delete $RESTARTR_HELM_RELEASE
    echo "finished deleting restartr"
  else
    echo "unknown option for restartr"
  fi
}


function dug(){
  if [ "$1" == "deploy" ]
  then
    echo "deploying dug"
    if [ $CREATE_STATIC_PV_STORAGE == true ]
    then
      dugStorage deploy
    fi

    HELM_VALUES="dug.neo4j.pvc_name=$DUG_NEO4J_PVC"
    HELM_VALUES+=",dug.redis.pvc_name=$DUG_REDIS_PVC"
    HELM_VALUES+=",dug.elasticsearch.app_name=$DUG_ES_APP_NAME"
    HELM_VALUES+=",dug.neo4j.app_name=$DUG_NEO4J_APP_NAME"
    HELM_VALUES+=",dug.redis.app_name=$DUG_REDIS_APP_NAME"
    HELM_VALUES+=",dug.web.app_name=$DUG_WEB_APP_NAME"
    HELM_VALUES+=",dug.search_client.app_name=$DUG_SC_APP_NAME"
    HELM_VALUES+=",dug.nboost.app_name=$DUG_NBOOST_APP_NAME"
    HELM_VALUES+=",dug.elasticsearch.deployment_name=$DUG_ES_APP_NAME"
    HELM_VALUES+=",dug.neo4j.deployment_name=$DUG_NEO4J_APP_NAME"
    HELM_VALUES+=",dug.redis.deployment_name=$DUG_REDIS_APP_NAME"
    HELM_VALUES+=",dug.web.deployment_name=$DUG_WEB_APP_NAME"
    HELM_VALUES+=",dug.search_client.deployment_name=$DUG_SC_APP_NAME"
    HELM_VALUES+=",dug.nboost.deployment_name=$DUG_NBOOST_APP_NAME"
    HELM_VALUES+=",dug.elasticsearch.service_name=$DUG_ES_APP_NAME"
    HELM_VALUES+=",dug.neo4j.service_name=$DUG_NEO4J_APP_NAME"
    HELM_VALUES+=",dug.redis.service_name=$DUG_REDIS_APP_NAME"
    HELM_VALUES+=",dug.web.service_name=$DUG_WEB_APP_NAME"
    HELM_VALUES+=",dug.search_client.service_name=$DUG_SC_APP_NAME"
    HELM_VALUES+=",dug.nboost.service_name=$DUG_NBOOST_APP_NAME"
    if [ ! -z "$DUG_ES_XMX" ]
    then
      HELM_VALUES+=",dug.elasticsearch.xmx=$DUG_ES_XMX"
    fi
    if [ ! -z "$DUG_ES_XMS" ]
    then
      HELM_VALUES+=",dug.elasticsearch.xms=$DUG_ES_XMS"
    fi
    if [ ! -z "DUG_ES_PV_STORAGECLASS" ]
    then
      HELM_VALUES+=",dug.elasticsearch.storage_class=$DUG_ES_PV_STORAGECLASS"
    fi
    if [ ! -z "DUG_NEO4J_PV_STORAGECLASS" ]
    then
      HELM_VALUES+=",dug.neo4j.storage_class=$DUG_NEO4J_PV_STORAGECLASS"
    fi
    if [ ! -z "DUG_REDIS_PV_STORAGECLASS" ]
    then
      HELM_VALUES+=",dug.redis.storage_class=$DUG_REDIS_PV_STORAGECLASS"
    fi
    HELM_VALUES+=",dug.create_pvcs=$DUG_CREATE_PVCS"
    if [ ! -z "$DUG_WEB_IMAGE_TAG" ]
    then
      HELM_VALUES+=",dug.web.image.tag=$DUG_WEB_IMAGE_TAG"
    fi
    if [ ! -z "$DUG_SC_IMAGE_TAG" ]
    then
      HELM_VALUES+=",dug.search_client.image.tag=$DUG_SC_IMAGE_TAG"
    fi
    if [ "$HELM_VALUES" = "" ]; then
      HELM_SET_ARG=""
    else
      HELM_SET_ARG="--set $HELM_VALUES"
    fi
    $HELM -n $NAMESPACE upgrade --install $DUG_HELM_RELEASE \
        $DUG_HELM_DIR $HELM_DEBUG --logtostderr $HELM_SET_ARG
    echo "finished deploying dug"
  elif [ "$1" == "delete" ]
  then
    echo "deleting dug"
    $HELM -n $NAMESPACE delete $DUG_HELM_RELEASE
    echo "finished deleting dug"
    if [ $CREATE_STATIC_PV_STORAGE == true ]
    then
      dugStorage delete
    fi
    if [ $DUG_ES_DELETE_STORAGE == true ]
    then
      # These will need to be changed if the number of replicas in dug change.
      kubectl -n $NAMESPACE delete pvc $DUG_ES_APP_NAME-data-$DUG_ES_APP_NAME-0
      kubectl -n $NAMESPACE delete pvc $DUG_ES_APP_NAME-data-$DUG_ES_APP_NAME-1
      kubectl -n $NAMESPACE delete pvc $DUG_ES_APP_NAME-data-$DUG_ES_APP_NAME-2
    fi
  else
    echo "unknown option for dug"
  fi
}


function dugStorage(){
  if [ "$1" == "deploy" ]
  then
    echo "# creating storage for Dug"
    if [ "$GKE_DEPLOYMENT" == true ]; then
      createGCEDisk $DUG_NEO4J_PD_NAME $DUG_NEO4J_PV_STORAGE_SIZE
      createGKEPV $DUG_NEO4J_PD_NAME $DUG_NEO4J_PV_NAME \
          $DUG_NEO4J_PV_STORAGE_SIZE $DUG_NEO4J_PVC
      createGKEPVC $DUG_NEO4J_PVC $DUG_NEO4J_PV_STORAGE_SIZE
      createGCEDisk $DUG_REDIS_PD_NAME $DUG_REDIS_PV_STORAGE_SIZE
      createGKEPV $DUG_REDIS_PD_NAME $DUG_REDIS_PV_NAME \
          $DUG_REDIS_PV_STORAGE_SIZE $DUG_REDIS_PVC
      createGKEPVC $DUG_REDIS_PVC $DUG_REDIS_PV_STORAGE_SIZE
    elif [ "$USE_NFS_PVS" == true ]
    then
      createNFSPV $DUG_NEO4J_PV_NAME $DUG_NEO4J_NFS_SERVER \
          $DUG_NEO4J_NFS_PATH $DUG_NEO4J_PV_STORAGECLASS \
          $DUG_NEO4J_PV_STORAGE_SIZE $DUG_NEO4J_PV_ACCESSMODE
      createPVC $DUG_NEO4J_PVC $DUG_NEO4J_PV_STORAGE_SIZE \
          $DUG_NEO4J_PV_ACCESSMODE $DUG_NEO4J_PV_STORAGECLASS
      createNFSPV $DUG_REDIS_PV_NAME $DUG_REDIS_NFS_SERVER \
          $DUG_REDIS_NFS_PATH $DUG_REDIS_PV_STORAGECLASS \
          $DUG_REDIS_PV_STORAGE_SIZE $DUG_REDIS_PV_ACCESSMODE
      createPVC $DUG_REDIS_PVC $DUG_REDIS_PV_STORAGE_SIZE \
          $DUG_REDIS_PV_ACCESSMODE $DUG_REDIS_PV_STORAGECLASS
    else
      createPVC $DUG_NEO4J_PVC $DUG_NEO4J_PV_STORAGE_SIZE \
          $DUG_NEO4J_PV_ACCESSMODE $DUG_NEO4J_PV_STORAGECLASS
      createPVC $DUG_REDIS_PVC $DUG_REDIS_PV_STORAGE_SIZE \
          $DUG_REDIS_PV_ACCESSMODE $DUG_REDIS_PV_STORAGECLASS
    fi
    echo "# finished creating storage for Dug"
  elif [ "$1" == "delete" ]
  then
    echo "# deleting storage for Dug"
    if [ "$GKE_DEPLOYMENT" == true ]; then
      deleteGKEPVC $DUG_NEO4J_PVC
      deleteGKEPV $DUG_NEO4J_PV_NAME
      if [ "$DUG_NEO4J_PD_DELETE_W_APP" == true ]; then
        echo "### Deleting Dug Neo4J Persistent disk."
        sleep $KUBE_WAIT_TIME
        deleteGCEDisk $DUG_NEO4J_PD_NAME
      else
        echo "### Not deleting Dug Neo4J Persistent disk."
      fi
      deleteGKEPVC $DUG_REDIS_PVC
      deleteGKEPV $DUG_REDIS_PV_NAME
      if [ "$DUG_REDIS_PD_DELETE_W_APP" == true ]; then
        echo "### Deleting Dug Redis Persistent disk."
        sleep $KUBE_WAIT_TIME
        deleteGCEDisk $DUG_REDIS_PD_NAME
      else
        echo "### Not deleting Dug Redis Persistent disk."
      fi
    elif [ "$USE_NFS_PVS" == true ]
    then
      if [ "$DUG_NEO4J_PD_DELETE_W_APP" == true ]; then
        deletePVC $DUG_NEO4J_PVC
        deleteNFSPV $DUG_NEO4J_PV_NAME $DUG_NEO4J_NFS_SERVER \
            $DUG_NEO4J_NFS_PATH $DUG_NEO4J_PV_STORAGECLASS \
            $DUG_NEO4J_PV_STORAGE_SIZE $DUG_NEO4J_PV_ACCESSMODE
      fi
      if [ "$DUG_REDIS_PD_DELETE_W_APP" == true ]; then
        deletePVC $DUG_REDIS_PVC
        deleteNFSPV $DUG_REDIS_PV_NAME $DUG_REDIS_NFS_SERVER \
            $DUG_REDIS_NFS_PATH $DUG_REDIS_PV_STORAGECLASS \
            $DUG_REDIS_PV_STORAGE_SIZE $DUG_REDIS_PV_ACCESSMODE
      fi
    else
      deletePVC $DUG_NEO4J_PVC
      deletePVC $DUG_REDIS_PVC
    fi
    echo "# finished deleting storage for Dug"
  fi
}


function deleteTychoApps(){
  if [ -z $NAMESPACE ]
  then
    NAMESPACE_ARG=""
  else
    NAMESPACE_ARG="-n $NAMESPACE"
  fi

  DEPLOY_NAMES=`kubectl $NAMESPACE_ARG get deploy -l executor=tycho | awk '{ if (NR>1) print $1 }'`
  for DEPLOY_NAME in $DEPLOY_NAMES
  do
    kubectl -n $NAMESPACE delete deploy $DEPLOY_NAME
    kubectl -n $NAMESPACE delete svc $DEPLOY_NAME
  done
}


case $APPS_ACTION in
  deploy)
    kubectl create namespace $NAMESPACE
    case $APP in
      all)
        deployDynamicPVCP
        if [ "$GKE_DEPLOYMENT" == true ];
        then
          deployNFSServer
        fi
        if [ "$NFSRODS_FOR_USER_DATA" == true ]
        then
          deployNFSRODS
        fi
        # deployELK
        deployCAT
        if [ "$RESTARTR_DEPLOYMENT" == true ]
        then
          restartr deploy
        fi
        if [ "$DUG_API" == true ]
        then
          dug deploy
        fi
        deployAmbassador
        deployNginxRevProxy
        # createNextflowStorage
        ;;
      ambassador)
        deployAmbassador
        ;;
      appstore)
        deployAppStore
        ;;
      appstoredata)
        createAppStoreData
        ;;
      commonsshare)
        deployCommonsShare
        ;;
      cat)
        deployCAT
        ;;
      dug)
        dug deploy
        ;;
      dugstorage)
        dugStorage deploy
        ;;
      dynamicpvcp)
        deployDynamicPVCP
        ;;
      efk)
        deployEFK
        ;;
      elk)
        deployELK
        ;;
      nextflowstorage)
        createNextflowStorage
        ;;
      nfs-server)
        deployNFSServer
        ;;
      nfsrods)
        deployNFSRODS
        ;;
      nginx-revproxy)
        deployNginxRevProxy
        ;;
      restartr)
        restartr deploy
        ;;
      tycho)
        deployTycho
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
        deleteTychoApps
        deleteNextflowStorage
        deleteNginxRevProxy
        deleteAmbassador
        if [ "$DUG_API" == true ]
        then
          dug delete
        fi
        if [ "$RESTARTR_DEPLOYMENT" == true ]
        then
          restartr delete
        fi
        deleteCAT
        # deleteELK
        if [ "$NFSRODS_FOR_USER_DATA" == true ]; then
          deleteNFSRODS
          deleteNFSRODSData
        fi
        if [ "$GKE_DEPLOYMENT" == true ];
        then
          deleteNFSServer
        fi
        deleteDynamicPVCP
        ;;
      apps)
        deleteNginxRevProxy
        deleteAmbassador
        if [ "$RESTARTR_DEPLOYMENT" == true ]
        then
          restartr delete
        fi
        deleteCAT
        if [ "$DUG_API" == true ]
        then
          dug delete
        fi
        # deleteELK
        # Not deleting NFSRODS b/c it has a PV.
        # if [ "$NFSRODS_FOR_USER_DATA" == true ]; then
        #   deleteNFSRODS
        # fi
        ;;
      ambassador)
        deleteAmbassador
        ;;
      appstore)
        deleteAppStore
        ;;
      appstoredata)
        deleteAppStoreData
        ;;
      cat)
        deleteCAT
        ;;
      commonsshare)
        deleteCommonsShare
        ;;
      dug)
        dug delete
        ;;
      dugstorage)
        dugStorage delete
        ;;
      dynamicpvcp)
        deleteDynamicPVCP
        ;;
      efk)
        deleteEFK
        ;;
      elk)
        deleteELK
        ;;
      nextflowstorage)
        deleteNextflowStorage
        ;;
      nfs-server)
        deleteNFSServer
        ;;
      nfsrods)
        deleteNFSRODS
        ;;
      nginx-revproxy)
        deleteNginxRevProxy
        ;;
      restartr)
        restartr delete
        ;;
      tycho)
        deleteTycho
        ;;
      tychoapps)
        deleteTychoApps
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
