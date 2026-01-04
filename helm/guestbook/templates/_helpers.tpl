{{- define "guestbook.namespace" -}}
{{- default .Release.Namespace .Values.namespace -}}
{{- end -}}
