{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "tiddles.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tiddles.fullname" -}}
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
{{- define "tiddles.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create frontend name
*/}}
{{- define "tiddles.frontend" -}}
{{- printf "%s-frontend" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create frontend name
*/}}
{{- define "tiddles.backend" -}}
{{- printf "%s-backend" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create mongodb name
*/}}
{{- define "tiddles.mongodb" -}}
{{- printf "%s-mongodb" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create tls secret name
*/}}
{{- define "tiddles.backendTLSSecretName" -}}
{{- printf "%s-backend-tls" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create tls secret name
*/}}
{{- define "tiddles.ingressTLSSecretName" -}}
{{- printf "%s-ingress-tls" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create temp namespace name
This is where the secret creation resources lives
Workaround if the chart is deployed in a istio enabled cluster
Using a temp namespace will ensure the istio sidecar is NOT auto injected to the secret creator job
*/}}
{{- define "tiddles.tempNamespaceName" -}}
{{- printf "%s-ns-temp" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create istio gateway name
*/}}
{{- define "tiddles.istioGatewayName" -}}
{{- printf "%s-gateway" (include "tiddles.fullname" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}