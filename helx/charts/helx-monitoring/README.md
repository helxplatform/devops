# helx-monitoring

Monitoring tools to use alongside HeLx

![Version: 0.1.6](https://img.shields.io/badge/Version-0.1.6-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

## Configuring helx-monitoring

This is a chart for deploying [loki-stack](https://github.com/grafana/helm-charts/tree/main/charts/loki-stack) and [kubecost](https://github.com/kubecost/cost-analyzer-helm-chart).  Currently it needs to be installed separately from the rest of HeLx.  The loki-stack chart needs to be installed in the loki-stack namespace and the kubecost chart needs to be installed in the kubecost namespace.  If the namespaces are changed then the service names in the chart values will also need to be changed.

## Install using Helm

```
helm repo add helxplatform https://helxplatform.github.io/devops/charts
helm repo update
helm upgrade --install loki-stack helxplatform/helx-monitoring -n loki-stack --create-namespace --set loki-stack.enabled=true
helm upgrade --install kubecost helxplatform/helx-monitoring -n kubecost --create-namespace --set cost-analyzer.enabled=true
```
## Use Port Forwarding to View the Web UI
```
# port forward for kubecost
kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090
# use web browser and go to http://localhost:9090

# get loki-stack user/password
kubectl -n loki-stack get secret loki-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
kubectl -n loki-stack get secret loki-stack-grafana -o jsonpath="{.data.admin-user}" | base64 -d ; echo
# port forward for loki-stack
kubectl port-forward --namespace loki-stack svc/loki-stack-grafana 3000:80
# use web browser and go to http://localhost:3000
```

## To Delete helx-monitoring
```
helm -n kubecost delete kubecost
helm -n loki-stack delete loki-stack
```

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://grafana.github.io/helm-charts | loki-stack | 2.4.1 |
| https://kubecost.github.io/cost-analyzer/ | cost-analyzer | 1.86.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cost-analyzer.enabled | bool | `false` |  |
| cost-analyzer.global.prometheus.enabled | bool | `false` |  |
| cost-analyzer.global.prometheus.fqdn | string | `"http://loki-stack-prometheus-server.loki-stack.svc"` |  |
| cost-analyzer.kubecostToken | string | `"your-token-goes-here"` |  |
| loki-stack.enabled | bool | `false` |  |
| loki-stack.grafana.enabled | bool | `true` |  |
| loki-stack.prometheus.alertmanager.persistentVolume.enabled | bool | `false` |  |
| loki-stack.prometheus.enabled | bool | `true` |  |
| loki-stack.prometheus.extraScrapeConfigs | string | `"- job_name: kubecost\n  honor_labels: true\n  scrape_interval: 1m\n  scrape_timeout: 10s\n  metrics_path: /metrics\n  scheme: http\n  dns_sd_configs:\n  - names:\n    - kubecost-cost-analyzer.kubecost\n    type: 'A'\n    port: 9003\n"` |  |
| loki-stack.prometheus.server.persistentVolume.enabled | bool | `false` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[0].job_name | string | `"prometheus"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[0].static_configs[0].targets[0] | string | `"localhost:9090"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].job_name | string | `"kubernetes-apiservers"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].kubernetes_sd_configs[0].role | string | `"endpoints"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].regex | string | `"default;kubernetes;https"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].source_labels[1] | string | `"__meta_kubernetes_service_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].relabel_configs[0].source_labels[2] | string | `"__meta_kubernetes_endpoint_port_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].scheme | string | `"https"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[1].tls_config.insecure_skip_verify | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].job_name | string | `"kubernetes-nodes"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].kubernetes_sd_configs[0].role | string | `"node"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[0].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[0].regex | string | `"__meta_kubernetes_node_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[1].replacement | string | `"kubernetes.default.svc:443"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[1].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[2].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[2].replacement | string | `"/api/v1/nodes/$1/proxy/metrics"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_node_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].relabel_configs[2].target_label | string | `"__metrics_path__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].scheme | string | `"https"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[2].tls_config.insecure_skip_verify | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].bearer_token_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/token"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].job_name | string | `"kubernetes-nodes-cadvisor"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].kubernetes_sd_configs[0].role | string | `"node"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[0].regex | string | `"(container_cpu_usage_seconds_total|container_memory_working_set_bytes|container_network_receive_errors_total|container_network_transmit_errors_total|container_network_receive_packets_dropped_total|container_network_transmit_packets_dropped_total|container_memory_usage_bytes|container_cpu_cfs_throttled_periods_total|container_cpu_cfs_periods_total|container_fs_usage_bytes|container_fs_limit_bytes|container_cpu_cfs_periods_total|container_fs_inodes_free|container_fs_inodes_total|container_fs_usage_bytes|container_fs_limit_bytes|container_cpu_cfs_throttled_periods_total|container_cpu_cfs_periods_total|container_network_receive_bytes_total|container_network_transmit_bytes_total|container_fs_inodes_free|container_fs_inodes_total|container_fs_usage_bytes|container_fs_limit_bytes|container_spec_cpu_shares|container_spec_memory_limit_bytes|container_network_receive_bytes_total|container_network_transmit_bytes_total|container_fs_reads_bytes_total|container_network_receive_bytes_total|container_fs_writes_bytes_total|container_fs_reads_bytes_total|cadvisor_version_info)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[0].source_labels[0] | string | `"__name__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[1].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[1].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[1].source_labels[0] | string | `"container"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[1].target_label | string | `"container_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[2].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[2].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[2].source_labels[0] | string | `"pod"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].metric_relabel_configs[2].target_label | string | `"pod_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[0].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[0].regex | string | `"__meta_kubernetes_node_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[1].replacement | string | `"kubernetes.default.svc:443"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[1].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[2].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[2].replacement | string | `"/api/v1/nodes/$1/proxy/metrics/cadvisor"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_node_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].relabel_configs[2].target_label | string | `"__metrics_path__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].scheme | string | `"https"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].tls_config.ca_file | string | `"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[3].tls_config.insecure_skip_verify | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].job_name | string | `"kubernetes-service-endpoints"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].kubernetes_sd_configs[0].role | string | `"endpoints"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[0].regex | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_scrape"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[1].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[1].regex | string | `"(https?)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_scheme"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[1].target_label | string | `"__scheme__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[2].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[2].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_path"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[2].target_label | string | `"__metrics_path__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[3].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[3].regex | string | `"([^:]+)(?::\\d+)?;(\\d+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[3].replacement | string | `"$1:$2"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[3].source_labels[0] | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[3].source_labels[1] | string | `"__meta_kubernetes_service_annotation_prometheus_io_port"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[3].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[4].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[4].regex | string | `"__meta_kubernetes_service_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[5].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[5].target_label | string | `"kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[6].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[6].source_labels[0] | string | `"__meta_kubernetes_service_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[6].target_label | string | `"kubernetes_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[7].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[7].source_labels[0] | string | `"__meta_kubernetes_pod_node_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[4].relabel_configs[7].target_label | string | `"kubernetes_node"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].job_name | string | `"kubernetes-service-endpoints-slow"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].kubernetes_sd_configs[0].role | string | `"endpoints"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[0].regex | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_scrape_slow"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[1].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[1].regex | string | `"(https?)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_scheme"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[1].target_label | string | `"__scheme__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[2].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[2].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[2].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_path"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[2].target_label | string | `"__metrics_path__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[3].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[3].regex | string | `"([^:]+)(?::\\d+)?;(\\d+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[3].replacement | string | `"$1:$2"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[3].source_labels[0] | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[3].source_labels[1] | string | `"__meta_kubernetes_service_annotation_prometheus_io_port"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[3].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[4].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[4].regex | string | `"__meta_kubernetes_service_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[5].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[5].target_label | string | `"kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[6].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[6].source_labels[0] | string | `"__meta_kubernetes_service_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[6].target_label | string | `"kubernetes_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[7].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[7].source_labels[0] | string | `"__meta_kubernetes_pod_node_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].relabel_configs[7].target_label | string | `"kubernetes_node"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].scrape_interval | string | `"5m"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[5].scrape_timeout | string | `"30s"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[6].honor_labels | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[6].job_name | string | `"prometheus-pushgateway"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[6].kubernetes_sd_configs[0].role | string | `"service"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[6].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[6].relabel_configs[0].regex | string | `"pushgateway"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[6].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_probe"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].job_name | string | `"kubernetes-services"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].kubernetes_sd_configs[0].role | string | `"service"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].metrics_path | string | `"/probe"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].params.module[0] | string | `"http_2xx"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[0].regex | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_service_annotation_prometheus_io_probe"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[1].source_labels[0] | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[1].target_label | string | `"__param_target"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[2].replacement | string | `"blackbox"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[2].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[3].source_labels[0] | string | `"__param_target"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[3].target_label | string | `"instance"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[4].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[4].regex | string | `"__meta_kubernetes_service_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[5].target_label | string | `"kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[6].source_labels[0] | string | `"__meta_kubernetes_service_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[7].relabel_configs[6].target_label | string | `"kubernetes_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].job_name | string | `"kubernetes-pods"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].kubernetes_sd_configs[0].role | string | `"pod"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[0].regex | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_scrape"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[1].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[1].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_path"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[1].target_label | string | `"__metrics_path__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[2].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[2].regex | string | `"([^:]+)(?::\\d+)?;(\\d+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[2].replacement | string | `"$1:$2"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[2].source_labels[0] | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[2].source_labels[1] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_port"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[2].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[3].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[3].regex | string | `"__meta_kubernetes_pod_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[4].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[4].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[4].target_label | string | `"kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[5].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_pod_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[5].target_label | string | `"kubernetes_pod_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[6].action | string | `"drop"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[6].regex | string | `"Pending|Succeeded|Failed"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[8].relabel_configs[6].source_labels[0] | string | `"__meta_kubernetes_pod_phase"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].job_name | string | `"kubernetes-pods-slow"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].kubernetes_sd_configs[0].role | string | `"pod"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[0].action | string | `"keep"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[0].regex | bool | `true` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[0].source_labels[0] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_scrape_slow"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[1].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[1].regex | string | `"(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[1].source_labels[0] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_path"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[1].target_label | string | `"__metrics_path__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[2].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[2].regex | string | `"([^:]+)(?::\\d+)?;(\\d+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[2].replacement | string | `"$1:$2"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[2].source_labels[0] | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[2].source_labels[1] | string | `"__meta_kubernetes_pod_annotation_prometheus_io_port"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[2].target_label | string | `"__address__"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[3].action | string | `"labelmap"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[3].regex | string | `"__meta_kubernetes_pod_label_(.+)"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[4].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[4].source_labels[0] | string | `"__meta_kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[4].target_label | string | `"kubernetes_namespace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[5].action | string | `"replace"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[5].source_labels[0] | string | `"__meta_kubernetes_pod_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[5].target_label | string | `"kubernetes_pod_name"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[6].action | string | `"drop"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[6].regex | string | `"Pending|Succeeded|Failed"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].relabel_configs[6].source_labels[0] | string | `"__meta_kubernetes_pod_phase"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].scrape_interval | string | `"5m"` |  |
| loki-stack.prometheus.serverFiles."prometheus.yml".scrape_configs[9].scrape_timeout | string | `"30s"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].name | string | `"CPU"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[0].expr | string | `"sum(rate(container_cpu_usage_seconds_total{container_name!=\"\"}[5m]))"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[0].record | string | `"cluster:cpu_usage:rate5m"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[1].expr | string | `"rate(container_cpu_usage_seconds_total{container_name!=\"\"}[5m])"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[1].record | string | `"cluster:cpu_usage_nosum:rate5m"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[2].expr | string | `"avg(irate(container_cpu_usage_seconds_total{container_name!=\"POD\", container_name!=\"\"}[5m])) by (container_name,pod_name,namespace)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[2].record | string | `"kubecost_container_cpu_usage_irate"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[3].expr | string | `"sum(container_memory_working_set_bytes{container_name!=\"POD\",container_name!=\"\"}) by (container_name,pod_name,namespace)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[3].record | string | `"kubecost_container_memory_working_set_bytes"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[4].expr | string | `"sum(container_memory_working_set_bytes{container_name!=\"POD\",container_name!=\"\"})"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[0].rules[4].record | string | `"kubecost_cluster_memory_working_set_bytes"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].name | string | `"Savings"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[0].expr | string | `"sum(avg(kube_pod_owner{owner_kind!=\"DaemonSet\"}) by (pod) * sum(container_cpu_allocation) by (pod))"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[0].labels.daemonset | string | `"false"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[0].record | string | `"kubecost_savings_cpu_allocation"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[1].expr | string | `"sum(avg(kube_pod_owner{owner_kind=\"DaemonSet\"}) by (pod) * sum(container_cpu_allocation) by (pod)) / sum(kube_node_info)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[1].labels.daemonset | string | `"true"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[1].record | string | `"kubecost_savings_cpu_allocation"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[2].expr | string | `"sum(avg(kube_pod_owner{owner_kind!=\"DaemonSet\"}) by (pod) * sum(container_memory_allocation_bytes) by (pod))"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[2].labels.daemonset | string | `"false"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[2].record | string | `"kubecost_savings_memory_allocation_bytes"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[3].expr | string | `"sum(avg(kube_pod_owner{owner_kind=\"DaemonSet\"}) by (pod) * sum(container_memory_allocation_bytes) by (pod)) / sum(kube_node_info)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[3].labels.daemonset | string | `"true"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[3].record | string | `"kubecost_savings_memory_allocation_bytes"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[4].expr | string | `"label_replace(sum(kube_pod_status_phase{phase=\"Running\",namespace!=\"kube-system\"} > 0) by (pod, namespace), \"pod_name\", \"$1\", \"pod\", \"(.+)\")"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[4].record | string | `"kubecost_savings_running_pods"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[5].expr | string | `"sum(rate(container_cpu_usage_seconds_total{container_name!=\"\",container_name!=\"POD\",instance!=\"\"}[5m])) by (namespace, pod_name, container_name, instance)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[5].record | string | `"kubecost_savings_container_cpu_usage_seconds"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[6].expr | string | `"sum(container_memory_working_set_bytes{container_name!=\"\",container_name!=\"POD\",instance!=\"\"}) by (namespace, pod_name, container_name, instance)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[6].record | string | `"kubecost_savings_container_memory_usage_bytes"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[7].expr | string | `"avg(sum(kube_pod_container_resource_requests_cpu_cores{namespace!=\"kube-system\"}) by (pod, namespace, instance)) by (pod, namespace)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[7].record | string | `"kubecost_savings_pod_requests_cpu_cores"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[8].expr | string | `"avg(sum(kube_pod_container_resource_requests_memory_bytes{namespace!=\"kube-system\"}) by (pod, namespace, instance)) by (pod, namespace)"` |  |
| loki-stack.prometheus.serverFiles."recording_rules.yml".groups[1].rules[8].record | string | `"kubecost_savings_pod_requests_memory_bytes"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
