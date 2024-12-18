{{/*
Expand the name of the chart.
*/}}
{{- define "shadowtraffic.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "shadowtraffic.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" (include "shadowtraffic.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "shadowtraffic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version }}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "shadowtraffic.labels" -}}
helm.sh/chart: {{ include "shadowtraffic.chart" . }}
{{ include "shadowtraffic.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "shadowtraffic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "shadowtraffic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
