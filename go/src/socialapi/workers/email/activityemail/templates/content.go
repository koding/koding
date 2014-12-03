package templates

const ContentLink = `
{{define "contentlink"}}
<b>
<a href="{{.Hostname}}/{{.Nickname}}" style="text-decoration: none; color: #52A840; font-weight: bold;">
  {{.Nickname}}
</a>
</b>
 {{.Action}}
<a href="{{.Hostname}}/Activity/Post/{{.Slug}}" style="text-decoration: none; font-weight: bold; color:#656565;">
  {{.ObjectType}}
</a>
{{end}}
`
