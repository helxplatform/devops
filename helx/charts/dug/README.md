# dug

![Version: 0.2.14](https://img.shields.io/badge/Version-0.2.14-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.4](https://img.shields.io/badge/AppVersion-1.0.4-informational?style=flat-square)

Helm chart for dug

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| create_pvcs | bool | `true` |  |
| elasticsearch.app_name | string | `"elasticsearch"` |  |
| elasticsearch.certs_secret | string | `"elastic-certificates"` |  |
| elasticsearch.cluster_name | string | `"dug-elasticsearch-cluster"` |  |
| elasticsearch.create_certs_secret | bool | `true` |  |
| elasticsearch.db_user | string | `"elastic"` |  |
| elasticsearch.image.pullPolicy | string | `"IfNotPresent"` |  |
| elasticsearch.image.repository | string | `"docker.elastic.co/elasticsearch/elasticsearch"` |  |
| elasticsearch.image.tag | string | `"7.9.1"` |  |
| elasticsearch.init.resources.limits.cpu | string | `"100m"` |  |
| elasticsearch.init.resources.limits.memory | string | `"128Mi"` |  |
| elasticsearch.init.resources.requests.cpu | string | `"50m"` |  |
| elasticsearch.init.resources.requests.memory | string | `"64Mi"` |  |
| elasticsearch.init_config_name | string | `"elasticsearch-initcontainer"` |  |
| elasticsearch.liveness.check_interval | int | `10` |  |
| elasticsearch.liveness.initial_delay | int | `30` |  |
| elasticsearch.nodes_com_port | int | `9300` |  |
| elasticsearch.pre_install.resources.limits.cpu | int | `1` |  |
| elasticsearch.pre_install.resources.limits.memory | string | `"128Mi"` |  |
| elasticsearch.pre_install.resources.requests.cpu | string | `"50m"` |  |
| elasticsearch.pre_install.resources.requests.memory | string | `"64Mi"` |  |
| elasticsearch.pvc_name | string | `"dug-elasticsearch-pvc"` |  |
| elasticsearch.replica_count | int | `3` |  |
| elasticsearch.resources.limits.cpu | int | `1` |  |
| elasticsearch.resources.limits.memory | string | `"3Gi"` |  |
| elasticsearch.resources.requests.cpu | string | `"50m"` |  |
| elasticsearch.resources.requests.memory | string | `"2304Mi"` |  |
| elasticsearch.rest_port | int | `9200` |  |
| elasticsearch.roles.data | string | `"true"` |  |
| elasticsearch.roles.ingest | string | `"true"` |  |
| elasticsearch.roles.master | string | `"true"` |  |
| elasticsearch.service.name | string | `"dug-elasticsearch"` |  |
| elasticsearch.storage_size | string | `"5Gi"` |  |
| elasticsearch.xms | string | `"2g"` |  |
| elasticsearch.xmx | string | `"2g"` |  |
| nboost.api_port | int | `8000` |  |
| nboost.app_name | string | `"nboost"` |  |
| nboost.image.pullPolicy | string | `"IfNotPresent"` |  |
| nboost.image.repository | string | `"koursaros/nboost"` |  |
| nboost.image.tag | string | `"0.3.9-pt"` |  |
| nboost.model | string | `"nboost/pt-biobert-base-msmarco"` |  |
| nboost.resources.limits.cpu | string | `"200m"` |  |
| nboost.resources.limits.memory | string | `"2Gi"` |  |
| nboost.resources.requests.cpu | string | `"50m"` |  |
| nboost.resources.requests.memory | string | `"128Mi"` |  |
| nboost.service.name | string | `"dug-nboost"` |  |
| neo4j.app_name | string | `"neo4j"` |  |
| neo4j.bolt_port | int | `7687` |  |
| neo4j.db_user | string | `"neo4j"` |  |
| neo4j.http_port | int | `7474` |  |
| neo4j.https_port | int | `7473` |  |
| neo4j.image.pullPolicy | string | `"IfNotPresent"` |  |
| neo4j.image.repository | string | `"bitnami/neo4j"` |  |
| neo4j.image.tag | string | `"3.5.14"` |  |
| neo4j.pvc_name | string | `"dug-neo4j-pvc"` |  |
| neo4j.resources.limits.cpu | string | `"200m"` |  |
| neo4j.resources.limits.memory | string | `"256Mi"` |  |
| neo4j.resources.requests.cpu | string | `"50m"` |  |
| neo4j.resources.requests.memory | string | `"64Mi"` |  |
| neo4j.service.name | string | `"dug-neo4j"` |  |
| neo4j.storage_size | string | `"1G"` |  |
| redis.app_name | string | `"redis"` |  |
| redis.image.pullPolicy | string | `"IfNotPresent"` |  |
| redis.image.repository | string | `"bitnami/redis"` |  |
| redis.image.tag | string | `"5.0.8"` |  |
| redis.pvc_name | string | `"dug-redis-pvc"` |  |
| redis.redis_port | int | `6389` |  |
| redis.resources.limits.cpu | string | `"200m"` |  |
| redis.resources.limits.memory | string | `"256Mi"` |  |
| redis.resources.requests.cpu | string | `"50m"` |  |
| redis.resources.requests.memory | string | `"64Mi"` |  |
| redis.service.name | string | `"dug-redis"` |  |
| redis.storage_size | string | `"5G"` |  |
| search_client.DUG_URL | string | `nil` |  |
| search_client.ambassador.ui.map_name | string | `"dug-ui"` |  |
| search_client.ambassador.ui.prefix | string | `"/ui"` |  |
| search_client.app_name | string | `"search-client"` |  |
| search_client.container_port | int | `8080` |  |
| search_client.extraEnv | object | `{}` |  |
| search_client.http_port | int | `80` |  |
| search_client.image.pullPolicy | string | `"IfNotPresent"` |  |
| search_client.image.repository | string | `"helxplatform/dug-search-client"` |  |
| search_client.image.tag | string | `"1.0.9"` |  |
| search_client.imagePullSecrets | list | `[]` |  |
| search_client.resources.limits.cpu | string | `"200m"` |  |
| search_client.resources.limits.memory | string | `"320Mi"` |  |
| search_client.resources.requests.cpu | string | `"50m"` |  |
| search_client.resources.requests.memory | string | `"64Mi"` |  |
| search_client.service.name | string | `"dug-search-client"` |  |
| secrets.name | string | `"dug-secrets"` |  |
| web.ambassador.search.map_name | string | `"dug-search"` |  |
| web.ambassador.search.prefix | string | `"/search"` |  |
| web.ambassador.search_kg.map_name | string | `"dug-search-kg"` |  |
| web.ambassador.search_kg.prefix | string | `"/search_kg"` |  |
| web.api_port | int | `5551` |  |
| web.app_name | string | `"web"` |  |
| web.crawl_command | string | `"tar -xf data/bdc_dbgap_data_dicts.tar.gz -C ./data && find ./data/ -type f -name '._*' -exec rm {} \\; && cp ./data/topmed_variables_v1.0.csv ./data/topmed_tags_v1.0.json ./data/bdc_dbgap_data_dicts/ && bin/dug crawl_dir data/bdc_dbgap_data_dicts"` |  |
| web.debug | bool | `false` |  |
| web.extraEnv | object | `{}` |  |
| web.image.pullPolicy | string | `"IfNotPresent"` |  |
| web.image.repository | string | `"helxplatform/dug"` |  |
| web.image.tag | string | `"1.0.9"` |  |
| web.imagePullSecrets | list | `[]` |  |
| web.resources.limits.cpu | string | `"250m"` |  |
| web.resources.limits.memory | string | `"256Mi"` |  |
| web.resources.requests.cpu | string | `"50m"` |  |
| web.resources.requests.memory | string | `"64Mi"` |  |
| web.service.name | string | `"dug-web"` |  |
| web.service.type | string | `"ClusterIP"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
