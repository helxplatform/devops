#!/bin/bash

# Run this script on the gh-pages branch to create Helm packages.

set -eo pipefail

./update-chart-dependencies.sh

helm package helx/charts/ambassador
helm package helx/charts/backup-pvc-cronjob
helm package helx/charts/helx-monitoring
helm package helx/charts/image-utils
helm package helx/charts/monitoring
helm package helx/charts/nfs-server
helm package helx/charts/nfsrods
helm package helx/charts/nginx
helm package helx/charts/pod-reaper
helm package helx/charts/search
helm package helx/charts/tycho-api
helm package helx

mv *.tgz docs/charts/
helm repo index docs/charts --url https://helxplatform.github.io/devops/charts
