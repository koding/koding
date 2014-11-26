package templates

const ContentLink = `
{{define "contentlink"}}
<b>
<a href="{{.Hostname}}/{{.Nickname}}" style="text-decoration: none; color:#222">
  {{.Nickname}}
</a>
</b>
 {{.Action}}
<a href="{{.Hostname}}/Activity/Post/{{.Slug}}">
  {{.ObjectType}}
</a>
{{end}}
`
