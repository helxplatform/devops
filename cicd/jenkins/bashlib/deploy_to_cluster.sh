#!/bin/bash                                                                                                                                            
function get_project() {
   # returns bdc, braini, or scidas
   arr_clstr=(${Cluster//-/ })
   if [ "${arrclstr[0]}" == "helx" ]; then ${arrclstr[0]}="bdc"; fi
   echo ${arrclstr[0]}
}

function get_clstr_type() {
   # returns dev, val, or prod
   arr_clstr=(${Cluster//-/ })
   echo ${arrclstr[1]}
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
   local -r applist=$1
   local -r brn=$2
   local -r clstr=$3

   echo "Enter ${FUNCNAME[0]}: applist=[$applist], branch=[$brn], cluster=[$clstr]"

   declare -A namespaces
   namespaces[helx-dev]="helx-dev"
   namespaces[helx-val]="helx-val"
   namespaces[helx-prod]="helx"
   namespaces[braini-dev]="braini-dev"
   namespaces[braini-prod]="braini"
   namespaces[scidas-prod]="default"

   for ea_app in $(echo $applist | tr "," " ")
   do
      echo "Deploying $ea_app"
      echo "helm -n namespaces[$clstr] delete $ea_app"
      echo "sleep 3"
      # TODO: come up with way to generalize --set tycho.image.tag=tycho_version
      echo "helm -n $spce install $ea_app $CLONE_HOME/helx/charts/$ea_app --set tycho.image.tag=$TYCHO_VERSION"
   done
   echo "Exit ${FUNCNAME[0]}"
}

function deploy_all () {
   local -r BRANCH=$1
   local -r CLONE_HOME="$WORKSPACE/devops"
   local -r APPSTORE_VER_FILE="$JENKINS_HOME/jobs/appstore/version/$BRANCH/ver"
   local -r TYCHO_VER_FILE="$JENKINS_HOME/jobs/tycho/version/$BRANCH/ver"

   echo "Enter ${FUNCNAME[0]}"
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
      deploy_all $BRANCH_NAME
   else
      deploy_app_list $App $Branch $Cluster
   fi
   echo "Exit ${FUNCNAME[0]}"
}

function pre_deploy() {
   echo "Enter ${FUNCNAME[0]}"
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

pre_deploy
deploy
