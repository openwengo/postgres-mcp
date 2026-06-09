{{/*
Renders the container `env:` entries from values.
Credentials are NOT rendered here — they come from the existing Secret via
envFrom (see deployment.yaml). Anything the Secret defines overrides these.
*/}}
{{- define "postgres-mcp.env" -}}
# --- Transport / server ---
- name: MCP_TRANSPORT
  value: {{ .Values.server.transport | quote }}
- name: PORT
  value: {{ .Values.server.port | quote }}
- name: MCP_HOST
  value: {{ .Values.server.host | quote }}
- name: LOG_LEVEL
  value: {{ .Values.server.logLevel | quote }}
{{- with .Values.server.toolFilter }}
- name: POSTGRES_TOOL_FILTER
  value: {{ . | quote }}
{{- end }}
{{- with .Values.server.instructionLevel }}
- name: MCP_INSTRUCTION_LEVEL
  value: {{ . | quote }}
{{- end }}
- name: TRUST_PROXY
  value: {{ .Values.server.trustProxy | quote }}
- name: MCP_ENABLE_HSTS
  value: {{ .Values.server.enableHsts | quote }}
{{- with .Values.server.rateLimitMax }}
- name: MCP_RATE_LIMIT_MAX
  value: {{ . | quote }}
{{- end }}
{{- with .Values.server.requestTimeoutMs }}
- name: MCP_REQUEST_TIMEOUT
  value: {{ . | quote }}
{{- end }}
{{- with .Values.server.headersTimeoutMs }}
- name: MCP_HEADERS_TIMEOUT
  value: {{ . | quote }}
{{- end }}
# --- Database (non-secret; credentials belong in existingSecret) ---
{{- with .Values.database.host }}
- name: PGHOST
  value: {{ . | quote }}
{{- end }}
{{- with .Values.database.port }}
- name: PGPORT
  value: {{ . | quote }}
{{- end }}
{{- with .Values.database.user }}
- name: PGUSER
  value: {{ . | quote }}
{{- end }}
{{- with .Values.database.name }}
- name: PGDATABASE
  value: {{ . | quote }}
{{- end }}
# --- OAuth 2.1 ---
{{- if .Values.oauth.enabled }}
- name: OAUTH_ENABLED
  value: "true"
{{- with .Values.oauth.issuer }}
- name: OAUTH_ISSUER
  value: {{ . | quote }}
{{- end }}
{{- with .Values.oauth.audience }}
- name: OAUTH_AUDIENCE
  value: {{ . | quote }}
{{- end }}
{{- with .Values.oauth.jwksUri }}
- name: OAUTH_JWKS_URI
  value: {{ . | quote }}
{{- end }}
{{- with .Values.oauth.clockTolerance }}
- name: OAUTH_CLOCK_TOLERANCE
  value: {{ . | quote }}
{{- end }}
{{- end }}
# --- Audit ---
{{- if .Values.audit.enabled }}
- name: AUDIT_LOG_PATH
  value: {{ .Values.audit.logPath | quote }}
- name: AUDIT_REDACT
  value: {{ .Values.audit.redact | quote }}
- name: AUDIT_READS
  value: {{ .Values.audit.reads | quote }}
{{- end }}
{{- with .Values.extraEnv }}
{{ toYaml . }}
{{- end }}
{{- end }}
