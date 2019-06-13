# heliumplus-k8s-devops-core

This resource deploys a Rstudio on the cloud and leveraging cloud scalable nature(using Google Kubernetes Engine) to support multiple 
users.
To capture audit logs for ecah command executed on the Rstudio terminal we use auditd. A filebeat agent is used to ship logs to the 
ELK stack deployed on the same cluster using Storage Classes, Headless Services and Stateful Sets.
I will provide walk-throughs for building resources on the cluster through the Google Cloud Shell (command line) as well as the 
Google Cloud Platform (GCP) console.

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
  
## TBD
### Rstudio Deployment.
1) Configure the filebeat to resolve the DNS for logstash instead of manually adding the logstash IP Address which is exposed using a LoadBlancer type Service.
2) Securing Communication between filebeat and Logstash using SSL.
3) Cluster specific settings.
