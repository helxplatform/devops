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

If you have setup a Google account for email configure these.  This is meant to be configured with [Google App Password](https://myaccount.google.com/apppasswords/) credentials.

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

## HeLx Deployment to GKE Cluster Using Centos 8

### Tools Setup for Centos 8

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
Create a text file named "env-vars-helx.sh" in the HeLx Platform directory. You may also create this file elsewhere and point to it with the CLUSTER_CONFIG variable below. It should contain the following variables that are used in the creation of the Kubernetes cluster.  Edit the variables as needed. At the very least you will need to update the PROJECT_ID.  Values with "< text >" need to be replaced with values for your environment.

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

Set a unique namespace for your deployment, perhaps using your name or part of your name.
```
export NAMESPACE=<namespace> # example: "jdoe_deploy"
```
Set GKE_DEPLOYMENT to "false".
```
export GKE_DEPLOYMENT=false
```
Set NGINX_SERVERNAME to the DNS hostname you want to use.
```
NGINX_SERVERNAME=< dns_name> # example: "helx.jdoe.cluster.edc.example.org"
```
It is suggested to use a static IP address for the HeLx web service.  If you do use a static IP address, then assign it to the NGINX_IP variable.  
```
export NGINX_IP=<"ip_address"> # example: "10.10.10.10"
```
Remove the NGINX_IP line if you are not using a static IP. You can use the command "kubectl get svc" to get the IP that is assigned to nginx-revproxy if you did not set a static IP.

If you plan to use HTTPS, create a TLS secret in the namespace you are using and set NGINX_TLS_SECRET to the name of the secret.  If you do not plan to use HTTPS, remove the NGINX_TLS_SECRET line.
```
NGINX_TLS_SECRET=< tls_secret > # example: jdoe-helx-tls-secret
```
Set APPSTORE_DJANGO_PASSWORD to a long, secure password for the admin user account in Django, which is used to administer users for HeLx.  Once HeLx is deployed you can use https://[your hostname]/admin to log in and create user accounts for the system.  If not set a random password will be generated.
```
export APPSTORE_DJANGO_PASSWORD=< admin_secret > # example: jdoe-dJaNGG0-53cret_Pa$$w0rd
```
For OAuth setup you can use Github, Google, or both.  To use Google you will set OAUTH_PROVIDERS to just "google" and for Github use "github".  If you want to use both set it to "google,github".

For Google OAuth you will need to log in to your GCP account and get an OAuth Client ID.
1) Point your browser to https://console.cloud.google.com/home/dashboard.  
2) Then follow: Navigation->APIs & Services->Credentials->CREATE CREDENTIALS->OAuth Client ID.
3) Choose Application Type: Web Application.
4) Enter a name for your application, e.g. jdoe-blackbalsam-google. The chosen name should be used for the GOOGLE_NAME environment variable below.
5) For Authorized javascript origins, enter your dns name: https://helx.jdoe.cluster.edc.example.org.  
6) For Authorized redirect URIs, enter: https://helx.jdoe.cluster.edc.example.org/google/login/callback/.
You will be supplied with Google Client ID and Google Secret, which need to be entered as environment variables.
```
export OAUTH_PROVIDERS="google"
export GOOGLE_NAME="jdoe-blackbalsam-google"
export GOOGLE_CLIENT_ID="12345678912-24m1q8va5qseq4sva8m3ottbbcbbao1.apps.googleusercontent.com"
export GOOGLE_SECRET="iABBc_2c_X_GeQOuq7MalxZ"
```
For EMAIL_HOST_USER and EMAIL_HOST_PASSWORD, you may simply enter "none" for now.
```
export EMAIL_HOST_USER="none"
export EMAIL_HOST_PASSWORD="none"
```
You can set specific images to use with APPSTORE_IMAGE, TYCHO_API_IMAGE, and NGINX_IMAGE, if you wish.
```
export APPSTORE_IMAGE="heliumdatastage/appstore:develop-v.0.0.51"
export TYCHO_API_IMAGE="heliumdatastage/tycho-api:develop-v0.0.38"
export NGINX_IMAGE="heliumdatastage/nginx:cca-v0.0.5"
```

The full file appears below with example values or placeholders which you'll need to replace with your own values:
```
export NAMESPACE="jdoe_deploy"
export GKE_DEPLOYMENT=false
export NGINX_SERVERNAME="helx.jdoe.cluster.edc.example.org"
export NGINX_IP="192.168.0.1"
export NGINX_TLS_SECRET="doe-helx-tls-secret"
export APPSTORE_DJANGO_PASSWORD="jdoe-dJaNGG0-53cret_Pa$$w0rd"
export OAUTH_PROVIDERS="google"
export GOOGLE_NAME="jdoe-blackbalsam-google"
export GOOGLE_CLIENT_ID="< SECRET HERE >"
export GOOGLE_SECRET="< SECRET HERE >"
export EMAIL_HOST_USER="none"
export EMAIL_HOST_PASSWORD="none"
# You can set specific images to use with these variables.
export APPSTORE_IMAGE="heliumdatastage/appstore:develop-v0.0.51"
export TYCHO_API_IMAGE="heliumdatastage/tycho-api:develop-v0.0.38"
export NGINX_IMAGE="heliumdatastage/nginx:cca-v0.0.5"
```
For Github OAuth, you need to create an OAuth App in the settings of your Github account.  
1) Go to the upper-right corner of any page, click your profile photo, then click Settings.
2) In the left sidebar, click Developer settings.
3) In the left sidebar, click OAuth Apps.
4) Click New OAuth App.
5) In "Application name", type the name of your app, e.g. jdoe-blackbalsam-github. You'll use this name as the env var GITHUB_NAME.
6) In "Homepage URL", type the full URL to your app's login page, e.g. https://[your hostname]/accounts/login.
7) You may optionally add a description of the application for users in the "Application description" field.
8) In "Authorization callback URL", type the callback URL of your app, e.g. "https://[your hostname]/accounts/github/login/callback/".
9) Click Register application.
10) Record the Client ID and Client Secret to put in the GITHUB_CLIENT_ID and GITHUB_SECRET environment variables.

```
export OAUTH_PROVIDERS="google"
export GITHUB_NAME="jdoe-blackbalsam-github"
export GITHUB_CLIENT_ID="1ab2c3de789123456789"
export GITHUB_SECRET="f4af51762caedab7aa123"
```


As seen below, the rest of the file remains the same except for the three GitHub variables. Again, please replace the values with your own values.

```
export NAMESPACE="jdoe_deploy"
export GKE_DEPLOYMENT=false
export NGINX_SERVERNAME="helx.jdoe.cluster.edc.example.org"
export NGINX_IP="192.168.0.1"
export NGINX_TLS_SECRET="doe-helx-tls-secret"
export APPSTORE_DJANGO_PASSWORD="jdoe-dJaNGG0-53cret_Pa$$w0rd"
export OAUTH_PROVIDERS="github"
export GITHUB_NAME="jdoe-blackbalsam-github"
export GITHUB_CLIENT_ID="1ab2c3de789123456789"
export GITHUB_SECRET="f4af51762caedab7aa123"
export EMAIL_HOST_USER="none"
export EMAIL_HOST_PASSWORD="none"
# You can set specific images to use with these variables.
export APPSTORE_IMAGE="heliumdatastage/appstore:develop-v0.0.51"
export TYCHO_API_IMAGE="heliumdatastage/tycho-api:develop-v0.0.38"
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

# Minimal Deployment to GKE Cluster Using HeLx Parent Helm Chart
Follow instructions in the "Tools Setup for Centos 8" and "Create Cluster in GKE Using Script" sections above.
```
helm install helx $HELXPLATFORM_HOME/devops/helx
```
It will take a few minutes for HeLx to deploy.  Follow the instructions in the output of the Helm command to log in as the Django admin.  Once logged in as the Django admin you can go to the HeLx URL and navigate to the apps section to create new apps.

To delete HeLx run this command.
```
helm delete helx
```
***NOTE***
You will need to delete any apps created with HeLx using the web UI or manually with kubectl commands.

# Minimal Deployment to Blackbalsam Kubernetes cluster using HeLx Parent Helm Chart in development mode
### Connecting to a cluster
```
Copy the kubeconfig generated by admin to ~/.kube/config
```
### A basic-values.py file for the HeLx chart

- Appstore/Nginx/Ambassador
```

# Override the default appstore values in the Appstore chart.
appstore:
  image:
    # Docker registry.
    respository: 
    # Uncomment this to specify a tag, defaults to latest.
    # tag: 
  userStorage:
    # Apps launched via Appstore need default volumes. When set to true, creates a stdnfs PVC.
    createPVC: true
  django:
    # Add authorized user email, this will get past the whitelisting step.
    AUTHORIZED_USERS: ""
    # Optional, for whitelisting.
    EMAIL_HOST_USER: ""
    # Optional, for whitelisting.
    EMAIL_HOST_PASSWORD: ""
    # Optional, OAuth Web App credentials.
    oauth:
      OAUTH_PROVIDERS: ""
      GOOGLE_NAME: ""
      GOOGLE_CLIENT_ID: ""
      GOOGLE_SECRET: ""
  ACCOUNT_DEFAULT_HTTP_PROTOCOL: https
  
  # Choosing a project ( cat | braini | scidas | reccap )
  djangoSettings: cat

# Override the default values in the NFS server chart.
nfs-server:
  enabled: false

# Override the default values in the Nginx chart.
nginx:
  service:
    # Internal static IP for the Nginx service already assigned by admin. 
    IP: 
    # Domain name already assigned by admin.
    serverName:
  # SSL certs already installed by admin in your namespace.
  SSL:
    nginxTLSSecret:
 
```
- Ambassador/Nginx in dev mode
```
    # Override the default values in the Nginx chart.
    nginx:
      DEV_PHASE:
        dev: True
    service:
      # Internal static IP for the Nginx service already assigned by admin.
      IP: 
      # Domain name already assigned by admin.
      serverName: 

   ```

### Installing the chart.
The parent Helm chart values gives the ability to enable/disable certain microservices/apps to be installed.
Using $HELXPLATFORM_HOME/devops/helx/values.yaml, enable Appstore/Nginx/Ambassador.

NOTE: Enable Ambassador/Nginx in development mode, if Appstore is running on localhost:port.
```
helm install release-name $HELXPLATFORM_HOME/devops/helx --values basic-values.yaml --namespace your-k8s-namespace
```
### Deleting the chart.
```
helm delete release-name --namespace your-k8s-namespace
```

