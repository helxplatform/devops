# Install helx

## Initial Setup

### Install helm3
1) [Download](https://github.com/helm/helm/releases) any helm3 release.
2) Unpack it using tar (tar -zxvf helm-v3.0.0-linux-amd64.tar.gz).
3) Move the helm binary to a desired location (mv linux-amd64/helm /usr/local/bin/helm).
4) Update PATH so helm is in it or export the HELM environment variable with it's full path.

### Clone HeLx Devops repo

```
export HELXPLATFORM_HOME=$HOME/src/helxplatform
export HELX_NAMESPACE=helx
mkdir -p $HELXPLATFORM_HOME
cd $HELXPLATFORM_HOME
git clone https://github.com/helxplatform/devops.git
```

## Install all charts using a single command
```
cd $HELXPLATFORM_HOME/devops
helm install release-name helx/ -n namespace
```

## Install charts individually
### Ambassador
1) Make a copy of the ambassador Helm chart values.yaml file and edit as needed.
```
cp $HELXPLATFORM_HOME/devops/helx/charts/ambassador/values.yaml ambassador-values.yaml
vi ambassador-values.yaml
```
2) Install the chart with Helm.

```
cd $HELXPLATFORM_HOME/devops/helx/charts/
helm install ambassador ambassador/ -n $HELX_NAMESPACE
```

### AppsStore
1) Make a copy of the appstore Helm chart values.yaml file and edit as needed.
```
cp $HELXPLATFORM_HOME/devops/helx/charts/appstore/values.yaml appstore-values.yaml
vi appstore-values.yaml
```
2) Install the chart with Helm.

```
cd $HELXPLATFORM_HOME/devops/helx/charts/
helm install appstore appstore/ -n $HELX_NAMESPACE
```

***NOTE***:

a) LoadBalancer IP won't be necessary when used with nginx reverse proxy and ambassador. Mapping for AppsStore is defined in the ambassador routing tables using service [annotations](https://github.com/helxplatform/devops/blob/f570196be7545df557debb82b8e69333dcd124ef/helx/charts/appstore/templates/csappstore-service.yml#L8-L18).  Ambassador maps all requests to "/" to the appstore service.

b) ambassador.flag has to be set to True, when using ambassador.

c) A PVC will be needed for persistent storage.

### nginx
1) Make a copy of the nginx Helm chart values.yaml file and edit as needed.
```
cp $HELXPLATFORM_HOME/devops/helx/charts/nginx/values.yaml nginx-values.yaml
vi nginx-values.yaml
```
2) Install the chart with Helm.

```
cd $HELXPLATFORM_HOME/devops/helx/charts/
helm install nginx-revproxy nginx/ -n $HELX_NAMESPACE
```

### tycho-api
1) Make a copy of the tycho-api Helm chart values.yaml file and edit as needed.
```
cp $HELXPLATFORM_HOME/devops/helx/charts/tycho-api/values.yaml tycho-api-values.yaml
vi tycho-api-values.yaml
```
2) Install the chart with Helm.

```
cd $HELXPLATFORM_HOME/devops/helx/charts/
helm install tycho-api tycho-api/ -n $HELX_NAMESPACE
```
***NOTE***:
A PVC will also need to be created before Helm chart is deployed.  This is used for user data.  The default PVC name is "stdnfs".

# Scripted Installs

To deploy HeLx 1.0 on the Google Kubernetes Engine you will need to have an account with Google Cloud Platform and configure the [Google Cloud SDK](https://cloud.google.com/sdk/docs/quickstarts) on your local system.  

## Centos 8 Configuration

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

# install helm3 (could be dangerous)
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Decide which directory you want the code to deploy HeLx to be and execute the following commands to checkout code from their GitHub repositories.  Some variables will need to be changed.  These commands were done in a BASH shell checked on MacOS and will probably work on Linux, maybe on Windows if you use Cygwin, the Windows Subsystem for Linux (WSL), or something similar.  Most variables can be set as either environment variables or within the configuration file.  Look towards the top of "devops/bin/gke-cluster.sh" to see a list of variables.

Create a text file named "env-vars-helx.sh" with the following that will contain a few variables that are used in the creation of the Kubernetes cluster.  Edit the variables as needed, at the very least you will need to update the PROJECT_ID.

```
export PROJECT="< Google project Id >" # Set this to your Google project ID.
export HELXPLATFORM_HOME=$HOME/src/helxplatform
export GKE_CLUSTER_CONFIG=$HOME/env-vars-helx.sh
export CLUSTER_NAME="$USER-cluster"
export CLUSTER_VERSION="1.17.12-gke.500" # Check what GKE supports.
```
After the variables file is changed open a terminal and change your current directory to where it is located.  Run the following commands to create the cluster.
```
source env-vars-helx.sh
# Create directory to hold the source repositories.
mkdir -p $HELXPLATFORM_HOME
cd $HELXPLATFORM_HOME
git clone https://github.com/helxplatform/devops.git
cd $HELXPLATFORM_HOME/devops/bin
./gke-cluster.sh deploy cluster
```

You should now have a running Kubernetes cluster on GKE.  Run a kubectl command to make sure you are connected to the cluster.
```
[vagrant@localhost bin]$ kubectl get no
NAME                                                 STATUS   ROLES    AGE    VERSION
gke-vagrant-cluster-dev-default-pool-b7fb2793-4093   Ready    <none>   114s   v1.17.12-gke.500
gke-vagrant-cluster-dev-default-pool-b7fb2793-q3p1   Ready    <none>   114s   v1.17.12-gke.500
```
To deploy HeLx into the cluster you need to add some environment variables to the env-vars-helx.sh file.  Values with "< text >" need to be replaced with values for your environment.

It is suggested to create a static external IP address in GCP in the same region that your cluster is in.  If that is done then create a DNS hostname that points to that address, if not then create a DNS hostname after HeLx has been deployed.  You can use the command  "kubectl get svc" to get the IP that is assigned to nginx-revproxy.  Set NGINX_IP if you have reserved a static IP address and remove if you did not.  Set NGINX_SERVERNAME to the DNS hostname you want to use.  Create a TLS secret in the same namespace as you are deploying HeLx and set the name to NGINX_TLS_SECRET.  If you do not want to use HTTPS then remove NGINX_TLS_SECRET.

Set APPSTORE_DJANGO_PASSWORD to a long, secure password for the admin user account in Django, which is used to administer users for HeLx.  Once HeLx is deployed you can use https://[your hostname]/admin to log in and create user accounts for the system.  For Django, also create a random, 50 character string and set that to SECRET_KEY.

For OAuth setup you will need to log in to your GCP account and add an OAuth Client ID.  Once logged in, navigate to "API & Services"->"Credentials" and create a new "OAuth client ID" with the application type of "Web application".  Add an entry to the "Authorized JavaScript origins" URIs for "https://[your hostname]" and to "Authorized redirect URIs" to "https://[your hostname]/accounts/google/login/callback/".  After the credentials are created set GOOGLE_NAME, GOOGLE_CLIENT_ID, and GOOGLE_SECRET.

To configure outgoing emails you will need to create a Google email account and setup an App Password for the email account.  Set EMAIL_HOST_USER and EMAIL_HOST_PASSWORD to what is setup.

```
export NAMESPACE="helx"
export NGINX_SERVERNAME="< helx.example.com >"
export NGINX_IP="< 192.168.0.1 >"
export NGINX_TLS_SECRET="< helx-tls-secret >"
export APPSTORE_IMAGE="heliumdatastage/appstore:develop-v0.0.40"
export TYCHO_API_IMAGE="heliumdatastage/tycho-api:develop-v0.0.27"
export NGINX_IMAGE="heliumdatastage/nginx:cca-v0.0.5"
export APPSTORE_DJANGO_PASSWORD="< SECRET HERE >"
export SECRET_KEY="< SECRET HERE (50 chars) >"
export OAUTH_PROVIDERS="google"
export GOOGLE_NAME="< Google OAuth App Name >"
export GOOGLE_CLIENT_ID="< SECRET HERE >"
export GOOGLE_SECRET="< SECRET HERE >"
export EMAIL_HOST_USER="< email@example.com >"
export EMAIL_HOST_PASSWORD="< SECRET HERE >"
```

### Commands to Deploy HeLx
```
$HELXPLATFORM_HOME/devops/bin/k8s-apps.sh -c $HOME/env-vars-helx.sh deploy all
```

### Commands to Delete HeLx
```
$HELXPLATFORM_HOME/devops/bin/k8s-apps.sh -c $HOME/env-vars-helx.sh delete all
```
### Commands to Delete Cluster
```
$HELXPLATFORM_HOME/devops/bin/gke-cluster.sh -c $HOME/env-vars-helx.sh delete cluster
```
