package templates

const ChannelLink = `
{{define "channellink"}}<a href="{{.Hostname}}/{{.Title}}">{{.Title}}</a>
{{end}}
`

const Message = `
{{define "message"}}
<tr>
  <td valign="top" style="color: #bbbbbb; font-size: 14px; padding: 14px 0 0 0; line-height: 18px; width: 60px; white-space: nowrap;">
    {{.Time}}
  </td>
  <td valign="top" style="font-size: 14px; word-break: break-word; line-height: 18px; padding: 13px 0 0 12px;">
  {{if .IsNicknameShown}}
    <span style="font-weight: bold; color:#656565; margin: 0 6px 0 0;">{{.Nickname}}:</span>
  {{end}}
    {{.Body}}
  </td>
</tr>
{{end}}
`
