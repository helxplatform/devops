# Install helx

## Install helm3
1) [Download](https://github.com/helm/helm/releases) any helm3 release.
2) Unpack it using tar (tar -zxvf helm-v3.0.0-linux-amd64.tar.gz).
3) Move the helm binary to a desired location (mv linux-amd64/helm /usr/local/bin/helm).

## Install all charts using a single command
```
helm install **release-name** helx/ -n namespace
```

## Install charts individually
### Ambassador
1) Edit the values.yaml (***Important***: service(ClusterIP or LoadBalancer) and prp(True or False)).
2) helm install **release-name** ambassador/ -n <namespace>


  
### AppsStore
1) Edit the values.yaml (***Important***: service(ClusterIP or LoadBalancer, ambassador.flag(True or False) and image).
2) helm install **release-name** appstore/ -n <namespace>

***NOTE***: 
a) LoadBalancer IP won't be necessary when used with nginx reverse proxy and ambassador. Mapping for AppsStore is defined in the ambassador routing tables using service [annotations](https://github.com/helxplatform/devops/blob/f570196be7545df557debb82b8e69333dcd124ef/helx/charts/appstore/templates/csappstore-service.yml#L8-L18). Ambassador maps all requests to "/" to the appstore service.
b) ambassador.flag has to be set to True, when using ambassador.

  
### nginx
1) Edit the values.yaml (***Important***: resolver(coredns.kube-system.svc or kube-dns.kube-system.svc)).
2) helm install **release-name** nginx/ -n <namespace>
  
***NOTE***: 
a) Use kube-dns.kube-system.svc for GKE clusters and coredns.kube-system.svc for on-prem clusters.
  
### tycho-api
1) Edit the values.yaml (***Important***: service(ClusterIP or LoadBalancer) and image).
2) Copy the role.yaml(for PRP) or serviceaccount.yaml(for SciDas and Braini) from /devops/helx to /devops/helx/charts/tycho-api/templates/. 

***NOTE***: 

a) role.yaml - set of permissions binding to a single namespace(service account) using Role and Rolebinding having access to only that namespace.      
b) serviceaccount.yaml - set of permissions binding to a single namespace(service account) using ClusterRole(cluster-admin) and ClusterRoleBinding having access to entire cluster.
c) The current version of tycho-api on Braini/Scidas needs a LoadBalancer IP, but the later versions we will not need that.

3) helm install **release-name** tycho-api/ -n <namespace>
  

# devops

To deploy HeLx 1.0 on the Google Kubernetes Engine you will need to have an account with Google Cloud Platform and configure the [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts) on your local system.  

Check your Google Cloud SDK is setup correctly.
```
glcoud info
```
Decide which directory you want the code to deploy HeLx to be and execute the following commands to checkout code from their GitHub repositories.  Some variables will need to be changed.  These commands were done in a BASH shell checked on MacOS and will probably work on Linux, maybe on Windows if you use Cygwin, the Windows Subsystem for Linux (WSL), or something similar.  Most variables can be set as either environment variables or within the configuration
file.  Look towards the top of "devops/bin/gke-cluster.sh"
to see a list of variables.
```
# Set the Google project ID that you want the cluster to be created in.
PROJECT="A_GOOGLE_PROJECT_ID"
# Check the Google console for what cluster versions are available to use.
# This can found in "Master version" property when you start the creation of
# a cluster.
CLUSTER_VERSION="1.15.11-gke.3"
HELXPLATFORM_HOME=$HOME/src/helxplatform
CLUSTER_NAME="$USER-cluster"
# Copy "hydroshare-secret.yaml" to
#   "$HELXPLATFORM_HOME/hydroshare-secret.yaml" or set
#   HYDROSHARE_SECRET_SRC_FILE to point to it's location below, which is
#   currently the default value.
HYDROSHARE_SECRET_SRC_FILE="$HELXPLATFORM_HOME/hydroshare-secret.yaml"
# The previous variables can also be exported instead of using a configuration
# file with GKE_CLUSTER_CONFIG exported below.
export GKE_CLUSTER_CONFIG=$HELXPLATFORM_HOME/env-vars-$USER-test-dev.sh

# Create directory to hold the source repositories.
mkdir -p $HELXPLATFORM_HOME
echo "export CLUSTER_NAME=$CLUSTER_NAME" > $GKE_CLUSTER_CONFIG
echo "export CLUSTER_VERSION=$CLUSTER_VERSION" >> $GKE_CLUSTER_CONFIG
echo "export PROJECT=$PROJECT" >> $GKE_CLUSTER_CONFIG
echo "export HYDROSHARE_SECRET_SRC_FILE=$HYDROSHARE_SECRET_SRC_FILE" >> $GKE_CLUSTER_CONFIG

cd $HELXPLATFORM_HOME
git clone https://github.com/helxplatform/CAT_helm.git
git clone https://github.com/helxplatform/devops.git

cd $HELXPLATFORM_HOME/devops/bin
# To create the cluster using the config file specified as a command line
# argument run this.
./gke-cluster.sh -c $GKE_CLUSTER_CONFIG deploy all

# ...or with the GKE_CLUSTER_CONFIG variable exported you can just run this.
# ./gke-cluster.sh deploy all

# Work with cluster and then terminate it.
echo "###"
echo "When you are done with the cluster you can terminate it with"
echo "these commands."
echo "export GKE_CLUSTER_CONFIG=$HELXPLATFORM_HOME/env-vars-$USER-test-dev.sh"
echo "cd $HELXPLATFORM_HOME/devops/bin"
echo "./gke-cluster.sh delete all"
```
# Doing Specific Installs

## Setup a Kubernetes Cluster.

Step-1: Before setting up a Kubernetes cluster we need to enable the Kubernetes Engine API.

Step-2: You can either using web based terminal provided by google(Google Cloud shell) or run the required command line interfaces on your own computers terminal.

Step-3: Ask Google cloud to create a "Kubernetes cluster" and a "default" node pool to get nodes from. Nodes represent the hardware and node pools will keep track how much of a certain type of hardware is required.
```
gcloud container clusters create \
  --machine-type n1-standard-2 \
  --image-type ubuntu \
  --num-nodes 2 \
  --zone us-east4-b \
  --cluster-version latest \
  <CLUSTERNAME>
```
To check if the cluster is initialized,
```
kubectl get node -o wide
```

Step-4: Give your account permissions to grant access to all the cluster-scoped resources(like nodes) and namespaced resources(like pods). RBAC(Role-based access control) should be used to regulate access to resources to a specific user based on the role.
```
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=<GOOGLE-EMAIL-ACCOUNT>
```
Create a "cluster-admin" role and a cluster role biding to bind the role to the user.

This project has four directories each one of each for Rstudio, Elasticsearch, Kibana and Logstash. Hence this project is 4-tier.
## Setup Elasticsearch
### Installing Elasticsearch
Step-1: Clone the repo and run the following command to deploy the Elasticsearch using the following command,
```
Kubectl apply -R -f elaticsearch/
```
Elasticsearch uses Staefulsets, Replicas, Storage classes, Persistent Volume Claims. A Headless Service acts as communication bridge to the pod. The Statefulsets
deploy elasticsearch nodes as an ordered index (eg: elasticsearch-0, elasticsearch-1 etc) and each node gets a persistent volume(data-
ealsticsearch-0) which are launched dynamically using Storage classes. A Persistent Volume Claim is used to bind the Storage class
definition to the elasticsearch Statefulset. One of the node will be elected as Master. Since a Headless Service is used, the clusterIP
should be None. Each pod or node of elasticsearch will be assigned a DNS name(eg: elasticsearch-0.es-nodes.default.svc.cluster.local etc).

Wait till all the pods are successfully launched.

## Setup Kibana
### Installing Kibana
Step-1: Run the following command to deploy the Kibana app. This is UI for the user to analyse the logs.
```
Kubectl apply -R -f kibana/
```

## Setup Logstash
### Installing Logstash
Step-1: Run the following commmand to deploy the Logstash.
```
Kubectl apply -R -f logstash/
```
The configuration for the Logstash is defined in a ConfigMap(logstash-configmap.yaml).

## Setup NFS server
### Installing NFS server
Step-1: The NFS server is backed by a google persistent disk. Make sure it exists prior to the deployment. If the persistent dosk does not exist, use the following command to create a disk on a google kubernetes cluster,
```
gcloud compute disks create gce-nfs-disk --size 10GB --zone us-central1-a
```
Step-2: Run the following command to deploy NFS server.
```
kubectl apply -R -f nfs-server
```

## TBD

This resource deploys a Rstudio on the cloud and leveraging cloud scalable nature(using Google Kubernetes Engine) to support multiple
users.
To capture audit logs for ecah command executed on the Rstudio terminal we use auditd. A filebeat agent is used to ship logs to the
ELK stack deployed on the same cluster using Storage Classes, Headless Services and Stateful Sets.
I will provide walk-throughs for building resources on the cluster through the Google Cloud Shell (command line) as well as the
Google Cloud Platform (GCP) console.

## Setup Rstudio
### Installing Rstudio
Step-1: Run the following command to deploy the Rstudio app.
```
Kubectl apply -R -f rstudio/
```
Rstudio uses API objects like Deployment, Persistent Volume Claim, Persistent Volume, Service, ConfigMaps.
Step-2: The persistent volume is manually created before this deployment using the command below,
```
gcloud compute disks create rstudio-disk-1 --zone us-east4-b --size 10GB --type pd-ssd
```
The name of the persistent disk shown above is rstudio-disk-1. It can be changed as per your requirement, but make sure to change this value in the PVC defined for Rstudio server.
The image used for the container is "muralikarthikk/rstudio-serv:v8" which is custom build to include pacakges like auditd and filebeat.
The ConfigMap is used to add more users on the Rstudio server. The format for defining the users is "username <uid> <gid>", seperated by tabs. Whenever a new user is added to the server. Change the PVC name to pvc-for-rstudio-<number> and re-deploy the application using the command shown in the beginning. The python script inside the container will add users as per the uid and gid mentioned and creates a home directory on the Rstudio server.
The Persistent Volume is used to persist the data stored by users. The PV still persists even when the Deployment, Service and ConfigMaps are deleted. Whenever any configuration is made to the Rstudio deployment, we can use the same PVC and PV to re-deploy the application.

Note: When a PVC is deleted. The claim for the PV is lost and the data on it is erased to make it available for re-claim.
The Persistent Volume Claim is used to bind the Rstudio app to the persistent disk created before.


### Rstudio Deployment.
1) Configure the filebeat to resolve the DNS for logstash instead of manually adding the logstash IP Address which is exposed using a LoadBlancer type Service.
2) Securing Communication between filebeat and Logstash using SSL.
3) Cluster specific settings.
