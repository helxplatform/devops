#!/bin/bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install --values postgres-values.yaml dataverse-postgres bitnami/postgresql
