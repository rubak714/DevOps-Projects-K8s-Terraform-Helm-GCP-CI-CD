# File: solution_helm/templates/_helpers.tpl

{{/* Expand the name of the chart */}}
{{- define "flask-int-m1.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate a fully qualified app name */}}
{{- define "flask-int-m1.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "flask-int-m1.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Chart name and version as used by the chart label */}}
{{- define "flask-int-m1.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels applied to all resources */}}
{{- define "flask-int-m1.labels" -}}
helm.sh/chart: {{ include "flask-int-m1.chart" . }}
{{ include "flask-int-m1.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels shared by Deployment selector, Pod template, and Service selector */}}
{{- define "flask-int-m1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-int-m1.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ServiceAccount name helper */}}
{{- define "flask-int-m1.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "flask-int-m1.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

