{{/*
Common labels
*/}}

{{- define "boutique.name" -}}
boutique
{{- end }}

{{- define "boutique.fullname" -}}
{{ include "boutique.name" . }}
{{- end }}