#!/bin/bash
export KUBECONFIG=/var/jenkins_home/deployment-secrets/$PRODUCT/$DEV-kubeconfig
export PATH=$HOME/helm/linux-amd64:$HOME/bin:$PATH

export APPSTORE_VERSION=$1
export TYCHO_VERSION=$2

WS=$WORKSPACE
GITDIR="devops"
CLONE_HOME="$WS/$GITDIR"

# Installing helm if does not exist.
if [ ! -d $HOME/helm ];
then
    mkdir $HOME/helm && cd $HOME/helm
	wget https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz && tar xvf helm-v3.0.2-linux-amd64.tar.gz
fi

# Installing kubectl if does not exist.
if [ ! -d $HOME/kubectl ];
then
	curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	mkdir $HOME/kubectl
	cp -r ./kubectl $HOME/kubectl
fi
chmod -R 755 $CLONE_HOME
#CLONE_HOME="/Users/singh/Desktop/helv-devops/devops"

# Deleting all then deploying all.
bash k8s-apps.sh -c $CLONE_HOME/cicd/$PRODUCT/$DEV.sh delete apps
sleep 30
bash k8s-apps.sh -c $CLONE_HOME/cicd/$PRODUCT/$DEV.sh deploy all