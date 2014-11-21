package templates

const MessageGroup = `
<tr>
  <td width="24px" valign="top">
    {{template "gravatar" .}}
  </td>
  <td style="padding: 24px 0 0 12px; line-height: 18px;">
    <b><a href="{{.Hostname}}/{{.Nickname}}" style="text-decoration: none; color:#222">{{.Nickname}}</a></b>{{.Title}}
    <div style="border-top: 1px solid #eaeaea; margin: 6px 0 0;"></iv>
    {{.Summary}}
  </td>
</tr>
`

const Message = `
{{define "message" }}
<div style="margin:6px 0 0;">
  <span style="color: #a5a5a5; font-weight: 200; margin: 0 6px 0 0;">{{.Time}}</span>
  {{.Body}}
</div>
{{end}}
`

const Gravatar = `
{{define "gravatar"}}
<img width="24px" height="24px" style="border-radius: 3px; padding-top: 24px;"
    src="https://gravatar.com/avatar/{{.Hash}}?size=24&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fimages%2Fdefault.avatar.24.png" />
{{end}}
`

const Channel = `
</br>
<b><a href="{{.Hostname}}/Activity/Message/{{.Name}}" style="text-decoration: none; color:#222"> {{.Title}}</a></b>
<table width="100%" style="margin: 12px 0; font-size: 14px; color: #353535;" cellpadding="0" cellspacing="0">
  {{.Summary}}
</table>
`
