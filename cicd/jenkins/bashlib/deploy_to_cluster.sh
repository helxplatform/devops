#!/bin/bash                                                                                                                                            
function get_project() {
   # bdc, braini, or scidas
   arrIN=(${Cluster//-/ })
   if [ "${arrIN[0]}" == "helx" ]; then ${arrIN[0]}="bdc"; fi
   echo ${arrIN[0]}
}

function get_clstr_type() {
   # dev, val, or prod
   arrIN=(${Cluster//-/ })
   echo ${arrIN[1]}
}

function read_version () {
    version_file=$1
    local version
    while read -r line; do
       version="$line"
    done < "$version_file"
    echo "$version"
}

function deploy_app_list () {
   echo "Enter ${FUNCNAME[0]}: Applist=[$App], Branch=[$Branch], Cluster=[$Cluster]"

   declare -A namespaces
   namespaces[helx-dev]="helx-dev"
   namespaces[helx-val]="helx-val"
   namespaces[helx-prod]="helx"
   namespaces[braini-dev]="braini-dev"
   namespaces[braini-prod]="braini"
   namespaces[scidas-prod]="default"
   local -r nspc=namespaces[$Cluster]

   for ea_app in $(echo $App | tr "," " ")
   do
      echo "Deploying $ea_app"
      echo "helm -n $nspc delete $ea_app"
      echo "sleep 3"
      # TODO: come up with way to generalize --set tycho.image.tag=tycho_version
      echo "helm -n $nspc install $ea_app $CLONE_HOME/helx/charts/$ea_app --set tycho.image.tag=$TYCHO_VERSION"
   done
   echo "Exit ${FUNCNAME[0]}"
}

function deploy_all () {
   echo "Enter ${FUNCNAME[0]}"

   local -r APPSTORE_VER_FILE="$JENKINS_HOME/jobs/appstore/version/$Branch/ver"
   local -r TYCHO_VER_FILE="$JENKINS_HOME/jobs/tycho/version/$Branch/ver"
   echo "APPSTORE_VER_FILE=[$APPSTORE_VER_FILE]"
   echo "TYCHO_VER_FILE=[$TYCHO_VER_FILE]"

   pwd
   ls -l
   cd "$CLONE_HOME/bin/"
   pwd
   ls -l
   APPSTORE_VERSION=`read_version "$APPSTORE_VER_FILE"`
   TYCHO_VERSION=`read_version "$TYCHO_VER_FILE"`
   echo "NOT INVOKING: auto_deploy.sh $APPSTORE_VERSION $TYCHO_VERSION"
   echo "Exit ${FUNCNAME[0]}"

}

function deploy () {
   echo "Enter ${FUNCNAME[0]}"
   if [ "$App" == "all" ]; then
      deploy_all
   else
      deploy_app_list $App $Branch $Cluster
   fi
   echo "Exit ${FUNCNAME[0]}"
}

function pre_deploy () {
   echo "Enter ${FUNCNAME[0]}"
   echo "${FUNCNAME[0]}: Cluster=[$Cluster]"
   project=`get_project`
   clstr_type=`get_clstr_type`
   echo "project=[$project], clstr_type=[$clstr_type]"
   echo "Deploying $applist apps to $Cluster which is a $project cluster for $clstr_type code."
   export PATH=$HOME/helm/linux-amd64:$HOME/kubectl:$HOME/bin:$PATH
   export KUBECONFIG=/var/jenkins_home/deployment-secrets/$project/$clstr_type-kubeconfig

   if [ -d $CLONE_HOME ]
   then
      chmod -R 755 $CLONE_HOME
      # Directory exists, remove it so git clone will work . . .
      echo "Removing existing devops directory for git clone."
      rm -rf $CLONE_HOME
   fi
   git clone https://github.com/helxplatform/devops.git
   echo "Exit ${FUNCNAME[0]}"
}

function init () {
   echo "Enter ${FUNCNAME[0]}"
   # GLOBALS
   App=$1
   Branch=$2
   Cluster=$3

   echo "${FUNCNAME[0]}: App=[$1] Branch=[$2] Cluster=[$3]"
   HOME="/var/jenkins_home"
   PATH="$HOME/helm/linux-amd64:$HOME/kubectl:$HOME/bin:$PATH"
   WORKSPACE="$HOME/workspace/deploy-to-cluster"
   CLONE_HOME="$WORKSPACE/devops"
   echo "Exit ${FUNCNAME[0]}"
}

init $1 $2 $3
pre_deploy
deploy
