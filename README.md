# HeLx

HeLx puts the most advanced analytical scientific models at investigator's finger tips using equally advanced cloud native, container orchestrated, distributed computing systems. HeLx can be applied in many domains. Its ability to empower researchers to leverage advanced analytical tools without installation or other infrastructure concerns has broad reaching benefits.

Contact [HeLx Help](mailto:catalyst-admin@lists.renci.org) with questions.

# Installing HeLx to a Kubernetes Cluster

These instructions aim at offering way to deploy, run and maintain a HeLx installation on any kind of Kubernetes-based cloud infrastructure.

You can use this on your laptop, in your on-prem datacenter or public cloud. With the power of Kubernetes, many scenarios are possible.

To install HeLx you will need access to a Kubernetes cluster.  This includes having kubectl installed and a kubeconfig with enough privileges to create resources in a namespace.  In our examples below we use "helx" as the namespace, so that will need to exist in your cluster.

## General Prerequisites

### Tools
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm version 3](https://helm.sh/docs/intro/install/)
- [git](https://git-scm.com/)

### Clone HeLx Devops repo

```
export HELXPLATFORM_HOME=$HOME/src/helxplatform
export NAMESPACE=helx
mkdir -p $HELXPLATFORM_HOME
cd $HELXPLATFORM_HOME
git clone https://github.com/helxplatform/devops.git
```

### Storage
AppStore and the Apps need PVCs to use for persistent storage.  Creation of this can vary between Kubernetes providers.  The AppStore disk can be pretty small, but the StdNFS disk will vary depending on how much storage your users need.

For GKE you can use the following command to create a disk to use.

```
export PROJECT="< Google project Id >"
export AVAILABILITY_ZONE="< availability zone >"
export APPSTORE_GCE_DISK="$USER-cluster-appstore-oauth-disk"
export STDNFS_GCE_DISK="$USER-cluster-stdnfs-disk"
gcloud compute disks create $APPSTORE_GCE_DISK --project $PROJECT --zone=$AVAILABILITY_ZONE --size=10GB
gcloud compute disks create $STDNFS_GCE_DISK --project $PROJECT --zone=$AVAILABILITY_ZONE --size=10GB
```

#### NFS Server (for GKE)

1) Make a copy of the nfs-server Helm chart values.yaml file and edit as needed.  For standard installations you can use the default values.

```
cp $HELXPLATFORM_HOME/devops/helx/charts/nfs-server/values.yaml $HELXPLATFORM_HOME/nfs-server-values.yaml
vi $HELXPLATFORM_HOME/nfs-server-values.yaml
```

2) Modify these variables in $HELXPLATFORM_HOME/nfs-server-values.yaml for your environment.

Set gcePersistentDiskPdName to "$USER-cluster-stdnfs-disk" (uncomment the line and replace $USER with your username).

```
 storage.gcePersistentDiskPdName
```

3) Install the chart with Helm.

```
helm install nfs-server $HELXPLATFORM_HOME/devops/helx/charts/nfs-server -n $NAMESPACE --values $HELXPLATFORM_HOME/nfs-server-values.yaml
```

### Individual Deployments

#### Ambassador
1) Make a copy of the ambassador Helm chart values.yaml file and edit as needed.  For standard installations you can use the default values.

```
cp $HELXPLATFORM_HOME/devops/helx/charts/ambassador/values.yaml $HELXPLATFORM_HOME/ambassador-values.yaml
vi $HELXPLATFORM_HOME/ambassador-values.yaml
```
2) Install the chart with Helm.

```
helm install ambassador $HELXPLATFORM_HOME/devops/helx/charts/ambassador -n $NAMESPACE --values $HELXPLATFORM_HOME/ambassador-values.yaml
```

#### AppStore

1) Make a copy of the appstore Helm chart values.yaml file and edit.  There are several variables that need to be set in the next step.

```
cp $HELXPLATFORM_HOME/devops/helx/charts/appstore/values.yaml $HELXPLATFORM_HOME/appstore-values.yaml
vi $HELXPLATFORM_HOME/appstore-values.yaml
```

2) Modify these variables in $HELXPLATFORM_HOME/appstore-values.yaml for your environment.

The Django admin user and password.

```
 django.APPSTORE_DJANGO_USERNAME
 django.APPSTORE_DJANGO_PASSWORD
```

Set a 50 charactor random string.

```
 django.SECRET_KEY
```

OAuth setup for user authentication.  You will need to configure Google, Github or both for user authentication.

```
 django.oauth.OAUTH_PROVIDERS = ( google | github | google,github )
```

Include these if using Github OAuth.

```
 django.oauth.GITHUB_NAME
 django.oauth.GITHUB_CLIENT_IT
 django.oauth.GITHUB_SECRET
```

Include these if using Google OAuth.

```
 django.oauth.GOOGLE_NAME
 django.oauth.GOOGLE_CLIENT_ID
 django.oauth.GOOGLE_SECRET
```

If you have setup a Google account for email configure these.  This is meant to be configured with [https://myaccount.google.com/apppasswords/](Google App Password) credentials.

```
 django.EMAIL_HOST_USER
 django.EMAIL_HOST_PASSWORD
```

3) Install the chart with Helm.

```
helm install appstore $HELXPLATFORM_HOME/devops/helx/charts/appstore/ -n $NAMESPACE --values $HELXPLATFORM_HOME/appstore-values.yaml
```

#### nginx
1) Make a copy of the nginx Helm chart values.yaml file and edit as needed.  There are several variables that need to be set in the next step.

```
cp $HELXPLATFORM_HOME/devops/helx/charts/nginx/values.yaml $HELXPLATFORM_HOME/nginx-values.yaml
vi $HELXPLATFORM_HOME/nginx-values.yaml
```

2) Modify these variables in $HELXPLATFORM_HOME/nginx-values.yaml for your environment.

The DNS hostname, static IP, and TLS certificate secret name (needs to exist in namespace) to use for the web server.

```
 service.serverName
 service.IP
 SSL.nginxTLSSecret
```

3) Install the Chart with Helm.

```
helm install nginx-revproxy $HELXPLATFORM_HOME/devops/helx/charts/nginx/ -n $NAMESPACE --values $HELXPLATFORM_HOME/nginx-values.yaml
```

#### tycho-api
1) Make a copy of the tycho-api Helm chart values.yaml file and edit as needed.  For standard installations you can use the default values.

```
cp $HELXPLATFORM_HOME/devops/helx/charts/tycho-api/values.yaml $HELXPLATFORM_HOME/tycho-api-values.yaml
vi $HELXPLATFORM_HOME/tycho-api-values.yaml
```

2) Install the chart with Helm.

```
helm install tycho-api $HELXPLATFORM_HOME/devops/helx/charts/tycho-api/ -n $NAMESPACE --values $HELXPLATFORM_HOME/tycho-api-values.yaml
```

***NOTE***:
A PVC will also need to be created before Helm chart is deployed.  This is used for user data.  The default PVC name is "stdnfs".

#### Add Users to the Authorized Users Group

Now that everything is installed you should be able to log in as the Django administrator.  Use the credentials that were set for APPSTORE_DJANGO_USERNAME/APPSTORE_DJANGO_PASSWORD in the appstore variables.  In a web browser go to https://[your hostname]/admin and log in.  Click on the link for "Core"->"Authorized Users" and add the emails for the Google or Github accounts associated with your users.  A user will not be able to use the same email for both Google and Github.


# Scripted Installs

To deploy HeLx 1.0 on the Google Kubernetes Engine you will need to have an account with Google Cloud Platform and configure the [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts) on your local system.  

## Centos 8 Workstation Configuration and Deployment to GKE Cluster

### Tools Setup

```
sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-sdk]
name=Google Cloud SDK
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

sudo yum -y install google-cloud-sdk
gcloud init
```
After the "gcloud init" command you will need to allow the Google SDK to access to your account and set the default project.

Check your Google Cloud Cloud SDK is setup correctly.

```
glcoud info
```

Install necessary packages for running cluster creation script.
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [helm](https://helm.sh/docs/intro/install/)

```
sudo bash -c "cat > /etc/yum.repos.d/kubernetes.repo" <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
sudo yum install -y kubectl git

# install helm3
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

### Cluster Environment Variables and Creation of Cluster in GKE
Create a text file named "env-vars-helx.sh" in the HeLx Platform directory (or elsewhere and adjust the CLUSTER_CONFIG variable below) with the following that will contain a few variables that are used in the creation of the Kubernetes cluster.  Edit the variables as needed, at the very least you will need to update the PROJECT_ID.  Values with "< text >" need to be replaced with values for your environment.

```
export PROJECT="< Google project Id >" # Set this to your Google project ID.
export AVAILABILITY_ZONE=us-east1-b
export HELXPLATFORM_HOME=$HOME/src/helxplatform
export CLUSTER_NAME="$USER-cluster"
export CLUSTER_VERSION="1.17.12-gke.500" # Check what GKE supports.
```

After the variables file is changed open a terminal and change your current directory to where it is located.  Run the following commands to create the cluster.

```
export HELXPLATFORM_HOME=$HOME/src/helxplatform
export CLUSTER_CONFIG=$HELXPLATFORM_HOME/env-vars-helx.sh

# Create directory to hold the source repositories.
mkdir -p $HELXPLATFORM_HOME
cd $HELXPLATFORM_HOME
git clone https://github.com/helxplatform/devops.git
cd $HELXPLATFORM_HOME/devops/bin
./gke-cluster.sh -c $CLUSTER_CONFIG deploy cluster
```

***NOTE***
Instead of using the "-c" flag with gke-cluster.sh you can source the environment file so that the variables are exported to your shell environment.  Another option is to just export the CLUSTER_CONFIG environment variable that points to your environment file.

You should now have a running Kubernetes cluster on GKE.  Run a kubectl command to make sure you are connected to the cluster.  You should get something similar to the following.

```
[vagrant@localhost bin]$ kubectl get no
NAME                                                 STATUS   ROLES    AGE    VERSION
gke-vagrant-cluster-dev-default-pool-b7fb2793-4093   Ready    <none>   114s   v1.17.12-gke.500
gke-vagrant-cluster-dev-default-pool-b7fb2793-q3p1   Ready    <none>   114s   v1.17.12-gke.500
```

### Configure Environment Variables for HeLx Deployment

To deploy HeLx into the cluster you need to add a few more environment variables the config file, in this document we use "env-vars-helx.sh".  

It is suggested to use a static IP address for the HeLx web service.  If you do use a static IP address then assign that to the NGINX_IP variable.  Remove the NGINX_IP line if you are not using a static IP.  Set NGINX_SERVERNAME to the DNS hostname you want to use.  Create a TLS secret in the same namespace as you are deploying HeLx and set NGINX_TLS_SECRET to the name of the secret.  If you do not want to use HTTPS then remove the NGINX_TLS_SECRET line.

Set APPSTORE_DJANGO_PASSWORD to a long, secure password for the admin user account in Django, which is used to administer users for HeLx.  Once HeLx is deployed you can use https://[your hostname]/admin to log in and create user accounts for the system.  For Django, also create a random, 50 character string and assign it to SECRET_KEY.

For OAuth setup you can use Github, Google, or both.  To use Google you will set OAUTH_PROVIDERS to just "google" and for Github use "github".  If you want to use both set it to "google,github".

For Google OAuth you will need to log in to your GCP account and add an OAuth Client ID.  Once logged in, navigate to "API & Services"->"Credentials" and create a new "OAuth client ID" with the application type of "Web application".  Add an entry to the "Authorized JavaScript origins" URIs for "https://[your hostname]" and to "Authorized redirect URIs" to "https://[your hostname]/accounts/google/login/callback/".  After the credentials are created set GOOGLE_NAME, GOOGLE_CLIENT_ID, and GOOGLE_SECRET.

For Github you will need to create an OAuth App in the settings of your Github account.  During the creation set "Homepage URL" to "https://[your hostname]/accounts/login" and "Authorization Callback URL" to "https://[your hostname]/accounts/github/login/callback/".  Add variables for GITHUB_NAME, GITHUB_CLIENT_ID, and GITHUB_SECRET in the variables file and assign the corresponding values after the OAuth App is created.

To configure outgoing emails you will need to create a Google email account and setup an App Password for the email account.  Set EMAIL_HOST_USER and EMAIL_HOST_PASSWORD to what is setup.

```
export NAMESPACE="helx"
export GKE_DEPLOYMENT=true
export USE_NFS_PVS=false
export NGINX_SERVERNAME="< helx.example.com >"
export NGINX_IP="< 192.168.0.1 >"
export NGINX_TLS_SECRET="< helx-tls-secret >"
export APPSTORE_DJANGO_PASSWORD="< SECRET HERE >"
export SECRET_KEY="< SECRET HERE (50 chars) >"
export OAUTH_PROVIDERS="google"
export GOOGLE_NAME="< Google OAuth App Name >"
export GOOGLE_CLIENT_ID="< SECRET HERE >"
export GOOGLE_SECRET="< SECRET HERE >"
export EMAIL_HOST_USER="< email@example.com >"
export EMAIL_HOST_PASSWORD="< SECRET HERE >"
# You can set specific images to use with these variables.
export APPSTORE_IMAGE="heliumdatastage/appstore:develop-v0.0.44"
export TYCHO_API_IMAGE="heliumdatastage/tycho-api:develop-v0.0.32"
export NGINX_IMAGE="heliumdatastage/nginx:cca-v0.0.5"
```

Add the environment variables mentioned in the "Environment Variables for HeLx Deployment" section above to "env-vars-helx.sh".  If you are not using the "-c" flag then source the environment file again.

It is suggested to create a static external IP address in GCP in the same region that your cluster is in.  Set NGINX_IP if you have reserved a static IP address and remove it if not.  You can use the command "kubectl get svc" to get the IP that is assigned to nginx-revproxy if you did not set a static IP.

### Commands to Deploy HeLx

```
$HELXPLATFORM_HOME/devops/bin/k8s-apps.sh -c $CLUSTER_CONFIG deploy all
```

### Commands to Delete HeLx

```
$HELXPLATFORM_HOME/devops/bin/k8s-apps.sh -c $CLUSTER_CONFIG delete all
```

***NOTE***
The defaults are set to not delete the GCE disks when deleting the apps.  To delete the disks also you can set the following environment variables.

```
export APPSTORE_OAUTH_PD_DELETE_W_APP=true
export GCE_NFS_SERVER_DISK_DELETE_W_APP=true
```

### Commands to Delete Cluster

```
$HELXPLATFORM_HOME/devops/bin/gke-cluster.sh -c $CLUSTER_CONFIG delete cluster
```
