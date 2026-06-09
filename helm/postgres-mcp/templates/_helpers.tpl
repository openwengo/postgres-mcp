{{/*
Expand the name of the chart.
*/}}
{{- define "postgres-mcp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "postgres-mcp.fullname" -}}
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

{{/*
Chart name and version label value.
*/}}
{{- define "postgres-mcp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "postgres-mcp.labels" -}}
helm.sh/chart: {{ include "postgres-mcp.chart" . }}
{{ include "postgres-mcp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "postgres-mcp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "postgres-mcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name to use.
*/}}
{{- define "postgres-mcp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "postgres-mcp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Container image reference (tag defaults to appVersion).
*/}}
{{- define "postgres-mcp.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion -}}
{{- printf "%s:%s" .Values.image.repository $tag -}}
{{- end }}

{{/*
Container args derived from values that are CLI-only or cleaner as flags.
Env vars cover most config; --stateless and --ssl have no env equivalent.
*/}}
{{- define "postgres-mcp.args" -}}
{{- if .Values.server.stateless }}
- --stateless
{{- end }}
{{- if .Values.database.ssl }}
- --ssl
{{- end }}
{{- with .Values.database.poolMax }}
- --pool-max
- {{ . | quote }}
{{- end }}
{{- end }}

{{/*
Default soft podAntiAffinity when the user supplies none, so replicas spread
across nodes for resilience under PDB/HPA without hard-scheduling failures.
*/}}
{{- define "postgres-mcp.affinity" -}}
{{- if .Values.affinity }}
{{- toYaml .Values.affinity }}
{{- else }}
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            {{- include "postgres-mcp.selectorLabels" . | nindent 12 }}
        topologyKey: kubernetes.io/hostname
{{- end }}
{{- end }}
