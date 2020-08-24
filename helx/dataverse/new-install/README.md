## Things changed from source

The files you send me in `source.zip` are partially used.
I changed

- Use FAKE DOI provider to avoid unnecessary clutter in logs and load at DataCite
- Skipped mailcatcher. Easy to re-integrate, just add to `resources`...
- Removed the env var mangling from the `check-db` init containers. Not sure how
  to improve the situation to make this easier to reuse. (see also below)
- Removed the S3 parts from the config map.

## Reproduce

### Create a small cluster
Assumption: you have minikube installed.

```
minikube start --memory 6144 --cpus 8 --disk-size 30g
```

### Install Postgres via Helm

```
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install --values postgres/postgres-values.yaml dv bitnami/postgresql
```

### Install Dataverse via Kustomize
This includes secrets. This is OK for testing, but you need to think about
how you avoid adding the secret to your helm values and keep it in sync with
the K8s secret used in the application.

```
kubectl apply -k .
```

### Bootstrap
This could be reused from the upstream file, when the PostgreSQL service wouldn't
have a different name due to Helm. This should be made easier one day.
If you feel like it, please open an issue.

```
kubectl create -f jobs/bootstrap.yaml
```

### Port-forward
To access via browser from `localhost:8080`, do

```
kubectl port-forward service/dataverse 8080
```
