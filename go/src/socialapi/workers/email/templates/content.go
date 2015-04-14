package templates

const Main = `
<div class="post" style="background: #fff; border-radius: 3px; padding: 24px 24px 34px 24px; margin-bottom: 6px;">
  <table width="100%" style="margin: 12px 0; font-size: 14px; color: #353535;" cellpadding="0" cellspacing="0">
    {{.Summary}}
  </table>
</div>
`

const Channel = `
<div class="post" style="background: #fff; border-radius: 3px; padding: 24px 24px 34px 24px; margin-bottom: 6px;">
  <table width="100%" style="margin: 12px 0; font-size: 14px; color: #353535;" cellpadding="0" cellspacing="0">
    <tr>
      <td width="35px"  valign="middle">
        {{.Image}}
      </td>
      <td valign="middle" style="font-size: 14px; padding: 0 0 0 16px;">
        {{.Link}}
      </td>
    </tr>
    <tr>
      <td width="35px" valign="middle"></td>
      <td valign="middle" style="font-size: 14px; padding: 0 0 0 16px;">
        <table width="100%" cellpadding="0" cellspacing="0">
          {{.Summary}}
        </table>
      </td>
    </tr>
  </table>
</div>
`

const ChannelLink = `
{{define "channellink"}}<a href="{{.Hostname}}/{{.Title}}">{{.Title}}</a>
{{end}}
`

const ProfileLink = `
<a href="{{.Hostname}}/{{.Nickname}}" style="text-decoration: none; color: #52A840; font-weight: bold;">{{.Nickname}}</a>
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

const Gravatar = `
<img width="35px" height="35px" style="background: #fafafa;"
    src="https://gravatar.com/avatar/{{.Hash}}?size=35&d=https%3A%2F%2Fkoding-cdn.s3.amazonaws.com%2Fimages%2Fdefault.avatar.35.png" />
`

const KodingLink = `<a href="koding.com" style="color: #52A840; text-decoration: none;">Koding.com</a>`
