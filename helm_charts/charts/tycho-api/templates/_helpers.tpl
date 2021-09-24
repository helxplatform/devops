{{/*
Expand the name of the chart.
*/}}
{{- define "tycho-api.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "tycho-api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "tycho-api.labels" -}}
service: {{ .Values.app.name }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "tycho-api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tycho-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "tycho-api.serviceAccount" -}}
name: {{ .Values.serviceAccount.name }}
{{- end -}}
