#!/bin/bash                                                                                                                                            

function get_project() {
   # bdc, braini, or scidas............... or helx while testing with helx-bb cluster
   arrIN=(${Cluster//-/ })
   if [ "${arrIN[0]}" == "helx" ]; then
      if [ "${arrIN[1]}" != "bb"  ]; then  # temp check while testing with helx-bb cluster
         arrIN[0]="bdc";
      fi
   fi
   echo ${arrIN[0]}
}

function get_clstr_type() {
   # dev, val, or prod ..... or bb while temporarily testing with helx-bb cluster
   arrIN=(${Cluster//-/ })
   echo ${arrIN[1]}
}

function deploy_app_list () {
   local -r NS=$1
   echo "Enter ${FUNCNAME[0]}: NS=[$ns], Applist=[$App], Branch=[$Branch], Cluster=[$Cluster]"

   for ea_app in $(echo $App | tr "," " ")
   do
      echo "Deploying $ea_app"
      echo "NOT INVOKING: helm -n $NS delete $ea_app"
      echo "sleep 3"

      if [ $Cluster == "helx-bb" ]; then
         VALUES_FILE="$HOME/deployment-secrets/$project/values.yaml"
      else
         VALUES_FILE"=$CLONE_HOME/helx/charts/$ea_app/values.yaml"
      fi
      echo "NOT_INVOKING: helm -n $NS install $ea_app helxplatform/$ea_app --values $VALUES_FILE"
   done
   echo "Exit ${FUNCNAME[0]}"
}

function deploy_all () {
   local -r NS=$1
   echo "Enter ${FUNCNAME[0]}: NS=[$ns]"
   if [ $Cluster == "helx-bb" ]; then
      VALUES_FILE="$HOME/deployment-secrets/$project/values.yaml"
   else
      VALUES_FILE="$CLONE_HOME/helx/values.yaml"
   fi
   echo "NOT INVOKING: helm -n $NS install helx helxplatform/helx --values $VALUES_FILE"
   echo "Exit ${FUNCNAME[0]}"
}

function deploy () {
   echo "Enter ${FUNCNAME[0]}"

   declare -A namespaces
   namespaces[helx-dev]="helx-dev"
   namespaces[helx-val]="helx-val"
   namespaces[helx-prod]="helx"
   namespaces[helx-bb]="helx"               # temp for testing with helx-bb cluster
   namespaces[braini-dev]="braini-dev"
   namespaces[braini-prod]="braini"
   namespaces[scidas-prod]="default"

   local -r nspc=${namespaces[$Cluster]}

   if [ "$App" == "all" ]; then
      deploy_all $nspc
   else
      deploy_app_list $nspc $App $Branch $Cluster
   fi
   echo "Exit ${FUNCNAME[0]}"
}

function pre_deploy () {
   echo "Enter ${FUNCNAME[0]}"
   echo "${FUNCNAME[0]}"
   echo "Cluster=[$Cluster]"
   project=`get_project`
   clstr_type=`get_clstr_type`
   echo "project=[$project], clstr_type=[$clstr_type]"
   echo "Deploying $applist apps to $Cluster which is a $project cluster for $clstr_type code."
   export PATH=$HOME/helm/linux-amd64:$HOME/kubectl:$HOME/bin:$PATH
   export KUBECONFIG=$HOME/deployment-secrets/$project/$clstr_type-kubeconfig

   ls -r CHARTS_URL="https://helxplatform.github.io/devops/charts"
   ls -r DEVOPS_URL="https://github.com/helxplatform/devops.git"

   $HELM repo add helxplatform $CHARTS_URL
   $HELM repo update

   if [ -d $CLONE_HOME ]
   then
      chmod -R 755 $CLONE_HOME
      # Directory exists, remove it so git clone will work . . .
      echo "Removing existing devops directory for git clone."
      rm -rf $CLONE_HOME
   fi
   git clone $DEVOPS_URL
   echo "Exit ${FUNCNAME[0]}"
}

function init () {
   echo "Enter ${FUNCNAME[0]}"
   App=$1
   Branch=$2
   Cluster=$3

   echo "${FUNCNAME[0]}: App=[$1] Branch=[$2] Cluster=[$3]"
   HOME="/var/jenkins_home"
   PATH="$HOME/helm/linux-amd64:$HOME/kubectl:$HOME/bin:$PATH"
   WORKSPACE="$HOME/workspace/deploy-to-cluster"
   CLONE_HOME="$WORKSPACE/devops"

   HELM="$HOME/helm/linux-amd64/helm"
   echo "Exit ${FUNCNAME[0]}"
}

init $1 $2 $3
pre_deploy
deploy
