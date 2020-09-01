#!/bin/bash
#set -x

path="`pwd`"
replace="cicd/$PRODUCT"
PATH_ENV="${path/bin/$replace}"

source $PATH_ENV/env.sh
source $JENKINS_HOME/deployment-secrets/$PRODUCT/$DEV-secrets.sh

# Environment variables for dev instance.
export PROJECT="nih-nhlbi-renci-copdgene-dev"
export REGION="us-east1"
export ZONE_EXTENSION="b"
export CLUSTER_ENV="val"
export CLUSTER_NAME="helx"
export NAMESPACE="helx-val"

#export APPSTORE_IMAGE="heliumdatastage/appstore:mastercca-v0.0.4"
#export TYCHO_API_IMAGE="heliumdatastage/tycho-api:mastercca-v0.0.3"

export APPSTORE_IMAGE="heliumdatastage/appstore:$BRANCH_NAME-$APPSTORE_VERSION"
export TYCHO_API_IMAGE="heliumdatastage/tycho-api:$BRANCH_NAME-$TYCHO_VERSION"
export NGINX_IMAGE="heliumdatastage/nginx:cca-v0.0.5"