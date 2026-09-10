{{- define "classicpress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "classicpress.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "classicpress.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "classicpress.labels" -}}
helm.sh/chart: {{ include "classicpress.chart" . }}
{{ include "classicpress.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "classicpress.selectorLabels" -}}
app.kubernetes.io/name: {{ include "classicpress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: classicpress
{{- end }}

{{- define "classicpress.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "classicpress.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "classicpress.mariadb.fullname" -}}
{{- printf "%s-mariadb" (include "classicpress.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "classicpress.mariadb.labels" -}}
helm.sh/chart: {{ include "classicpress.chart" . }}
{{ include "classicpress.mariadb.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{- define "classicpress.mariadb.selectorLabels" -}}
app.kubernetes.io/name: {{ include "classicpress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: mariadb
{{- end }}

{{- define "classicpress.image" -}}
{{- if .Values.image.digest }}
{{- printf "%s@%s" .Values.image.repository .Values.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.image.repository (default .Chart.AppVersion .Values.image.tag) }}
{{- end }}
{{- end }}

{{- define "classicpress.mariadb.image" -}}
{{- if .Values.mariadb.image.digest }}
{{- printf "%s@%s" .Values.mariadb.image.repository .Values.mariadb.image.digest }}
{{- else }}
{{- printf "%s:%s" .Values.mariadb.image.repository .Values.mariadb.image.tag }}
{{- end }}
{{- end }}

{{- define "classicpress.database.host" -}}
{{- if .Values.database.host }}
{{- .Values.database.host }}
{{- else if .Values.mariadb.enabled }}
{{- include "classicpress.mariadb.fullname" . }}
{{- else }}
{{- fail "database.host is required when mariadb.enabled is false" }}
{{- end }}
{{- end }}

{{- define "classicpress.database.secretName" -}}
{{- default (printf "%s-db" (include "classicpress.fullname" .)) .Values.database.existingSecret }}
{{- end }}

{{- define "classicpress.database.passwordKey" -}}
{{- if .Values.database.existingSecret }}
{{- .Values.database.existingSecretPasswordKey }}
{{- else }}
{{- print "password" }}
{{- end }}
{{- end }}

{{- define "classicpress.salts.secretName" -}}
{{- default (printf "%s-salts" (include "classicpress.fullname" .)) .Values.classicpress.existingSecret }}
{{- end }}

{{- define "classicpress.pvcName" -}}
{{- default (include "classicpress.fullname" .) .Values.persistence.existingClaim }}
{{- end }}

{{/*
Reuse a value already stored in a secret so upgrades never rotate it.
Usage: include "classicpress.retainedValue" (dict "secret" $secret "key" "password" "default" $generated)
*/}}
{{- define "classicpress.retainedValue" -}}
{{- $existing := "" }}
{{- if .secret }}
{{- $existing = index (.secret.data | default dict) .key | default "" }}
{{- end }}
{{- if $existing }}
{{- $existing }}
{{- else }}
{{- .default | b64enc }}
{{- end }}
{{- end }}
