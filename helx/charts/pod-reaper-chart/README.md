# Pod Reaper Helm Chart

# Deployment

## Pre-requisites:

## Configuring Pod Reaper

Pod-Reaper is configurable through environment variables. The pod-reaper specific environment variables are:

- `NAMESPACE` the kubernetes namespace where pod-reaper should look for pods
- `GRACE_PERIOD` duration that pods should be given to shut down before hard killing the pod
- `SCHEDULE` schedule for when pod-reaper should look for pods to reap
- `RUN_DURATION` how long pod-reaper should run before exiting
- `REQUIRE_LABEL_KEY` pod metadata label (of key-value pair) that pod-reaper should require
- `REQUIRE_LABEL_VALUES` comma-separated list of metadata label values (of key-value pair) that pod-reaper should require
- `LOG_LEVEL` messages this level and above will be logged. Available logging levels: Debug, Info, Warning, Error, Fatal and Panic
- `DRY_RUN` when true, the pod-reaper will select the pods but not actually reap them 

## Implemented Rules
At least one rule must be enabled, or the pod-reaper will error and exit. See the Rules section below for configuring and enabling rules.

- `MAX_DURATION` duration of the running pod, the pod-reaper should wait before reaping it

## Example pod-reaper configuration with rules in values.yaml

reapers is an array, can configure multiple such reapers.

```
reapers:
  short-running-apps:
    namespace: "test-namespace"
    grace_period: 10m
    schedule: "@every 1m"
    run_duration: "0s"
    require_label_key: "app-name"
    require_label_values: "jupyter-ds,imagej,napari,cloud-top,dicom-cloudtop,dicom-gh,blackbalsam,gsforge"
    dry_run: "false"
    log_level: "Info"
    log_format: "Logrus"
    max_duration: "1h"
 ```
 
 ## Install using Helm
 
 helm install <any-name> pod-reaper-chart/ -n <namespace>
