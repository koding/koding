package templates

const ContentLink = `
{{define "contentlink"}}
{{.Action}}
<a href="{{.Hostname}}/Activity/Post/{{.Slug}}">
  {{.ObjectType}}
</a>
{{end}}
`
