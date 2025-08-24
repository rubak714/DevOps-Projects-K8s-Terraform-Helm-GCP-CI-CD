{{/* Expand the name of the chart. */}}
{{- define "flask-helm-m1.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Generate a fully qualified name for resources. */}}
{{- define "flask-helm-m1.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name (include "flask-helm-m1.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/* Compose chart name and version for labels like helm.sh/chart */}}
{{- define "flask-helm-m1.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Common labels applied to all resources */}}
{{- define "flask-helm-m1.labels" -}}
helm.sh/chart: {{ include "flask-helm-m1.chart" . }}
{{ include "flask-helm-m1.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/* Selector labels shared by Deployment selector, pod template, and Service selector */}}
{{- define "flask-helm-m1.selectorLabels" -}}
app.kubernetes.io/name: {{ include "flask-helm-m1.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* ServiceAccount name helper */}}
{{- define "flask-helm-m1.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "flask-helm-m1.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/* Secret name helper: external secret expected to exist out-of-band */}}
{{- define "flask-helm-m1.secretName" -}}
{{ printf "%s-secrets" (include "flask-helm-m1.fullname" .) }}
{{- end -}}
