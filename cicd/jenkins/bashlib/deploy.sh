#!/bin/bash

# Script to kick off no-code deployments.  
#   Downloads the generic deployment script from GitHub and invokes it.
#   To invoke: /var/jenkins_home/build/deploy.sh
#      ex: /var/jenkins_home/build/deploy.sh

E_BADARGS=85
DEPLOY_SCRIPT=deploy_to_cluster.sh

if [ $# -ne 0 ]
then
  echo "Usage: `basename $0`"
  exit $E_BADARGS
fi

BUILD_SCRIPT_URL="https://raw.githubusercontent.com/helxplatform/devops/master/cicd/jenkins/bashlib/$DEPLOY_SCRIPT"
curl $BUILD_SCRIPT_URL > deploy.sh
. ./deploy.sh
