{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "fortio.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fortio.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "fortio.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create data volume name from fullname
*/}}
{{- define "fortio.dataVolumeName" -}}
{{- printf "%s-data" (include "fortio.fullname" .) | replace "+" "_"  | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create tls secret name from fullname
*/}}
{{- define "fortio.tlsSecretName" -}}
{{- printf "%s-tls" (include "fortio.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create iap secret name from fullname
*/}}
{{- define "fortio.iapSecretName" -}}
{{- printf "%s-iap" (include "fortio.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "fortio.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "fortio.fullname" .) .Values.serviceAccount.name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end -}}
{{- end -}}

{{/*
Create temp namespace name
This is where the secret creation resources lives
Workaround if the chart is deployed in a istio enabled cluster
Using a temp namespace will ensure the istio sidecar is NOT auto injected to the secret creator job
*/}}
{{- define "fortio.tempNamespaceName" -}}
{{- printf "%s-ns-temp" (include "fortio.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}