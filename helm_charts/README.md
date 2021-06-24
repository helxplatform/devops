# CAT_helm
We’re creating a Helm 3.0 deployment and expect an alpha to be available November 6th.

The Helm chart source is here:
https://github.com/heliumplusdatastage/CAT_helm.git

These are the commands to run it on GKE.

Prerequisites: 
1) Install helm3.
2) Clone the repo.

Step-1: Appstore postgres DB requires a persistent disk with a name (appsstore-db-volume). Use the command to create a persistent disk,

If on GCP GKE,

```gcloud compute disks create appstore-db-volume --size 5Gi --zone <Cluster zone>```

Step-2: The tycho-api requires a cluster-role, binding and service account with cluster-admin access. Since the scope of these resources is cluster-wide, execute the following commands on the cluster to check if the resources(tycho-api-access ClusterRole and binding, default ServiceAccount) already exist.

```kubectl get clusterrole```

```kubectl get clusterrolebinding```

```kubectl get serviceaccount```

If they don't exist, move the role.yaml and serviceaccount.yaml into the "CAT_helm/charts/tycho-api/templates" directory.

Step-3: Deploy chart using the command below,

```helm install <Name> ./CAT_helm --namespace <desired namespace>```


# Here are kubectl commands showing its status after it’s installed.

Use the command below to get the list of pods,

```kubectl get pods --namespace <desired namespace>```

Use the command below to get the list of services,

```kubectl get svc --namespace <desired namespace>```

Use the command below to get a detailed description of the pod,

```kubectl describe pods <name of the pod> --namespace <desired namespace>```
# helm_charts
