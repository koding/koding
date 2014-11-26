package templates

const Main = `
{{.Title}}
<table width="100%" style="margin: 12px 0; font-size: 14px; color: #353535;" cellpadding="0" cellspacing="0">
  {{.Summary}}
</table>
`

const Channel = `
<tr>
  <td width="24px" valign="top">
  {{.Image}}
  </td>
  <td style="padding: 24px 0 0 12px; line-height: 18px;">
    {{.Link}}
    <div style="border-top: 1px solid #eaeaea; margin: 6px 0 0;"></div>
    {{.Summary}}
  </td>
</tr>
`

const ChannelLink = `
{{define "channellink"}}
<b>
  <a href="{{.Hostname}}/Activity/Message/{{.ChannelId}}" style="text-decoration: none; color:#222">{{.Title}}</a>
</b>
{{end}}
`

const ProfileLink = `
<b>
  <a href="{{.Hostname}}/{{.Nickname}}" style="text-decoration: none; color:#222">{{.Nickname}}</a>
</b>
`

const Message = `
{{define "message"}}
<div style="margin:6px 0 0;">
  <span style="color: #a5a5a5; font-weight: 200; margin: 0 6px 0 0;">{{.Time}}</span>
  {{if .IsNicknameShown}}
    <span style="font-weight: 600; margin: 0 6px 0 0;">{{.Nickname}}:</span>
  {{end}}
  {{.Body}}
</div>
{{end}}
`

const Gravatar = `
<img width="24px" height="24px" style="border-radius: 3px; padding-top: 24px;"
    src="https://gravatar.com/avatar/{{.Hash}}?size=24&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fimages%2Fdefault.avatar.24.png" />
`
