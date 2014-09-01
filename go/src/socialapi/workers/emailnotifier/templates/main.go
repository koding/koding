package templates

const Main = `
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
        "http://www.w3.org/TR/REC-html40/loose.dtd">
<html>
<head><title>[Koding]</title></head>
<body>
  <table class="main-table" cellspacing="0">
    <!-- HEADER -->
    <tr class="header">
      <td class="header-logo">
        <!-- Koding Logo with pure table -->
        <table width="40px" height="40px" class="logo" cellspacing="2" cellpadding="2">
          <tr class="bar-0">
              <td height="1px" colspan="3">&nbsp;</td>
          </tr>
          <tr class="bar-1">
              <td height="1px">&nbsp;</td>
              <td height="1px" colspan="2">&nbsp;</td>
          </tr>
          <tr class="bar-2">
              <td height="1px" colspan="3">&nbsp;</td>
          </tr>
        </table><br/>
      </td>
      <td class="intro">
        <h2>Hello {{.FirstName}},</h2>
        <p>{{.Description}}</p>
      </td>
      <td class="date">
        <p>{{.CurrentDate}}</p>
      </td>
    </tr>
    {{.Content}}
    {{template "footer" . }}
  </table>
</body>
</html>
`

const Footer = `
    {{define "footer"}}
    <!-- FOOTER -->
    <tr height="90%" class="footer-before">
      <td></td>
      <td height="40px" colspan="2"></td>
    </tr>
    <tr class="footer">
      <td></td>
      <td colspan="2">
        {{template "unsubscribe" . }}
        <br/>
        <a href="{{.Uri}}">Koding</a>,
         Inc. 358 Brannan, San Francisco, CA 94107
      </td>
    </tr>
    {{end}}
`

const Unsubscribe = `
    {{if .Unsubscribe.ShowLink }}
    Unsubscribe from <a href="{{.Uri}}/Unsubscribe/{{.Unsubscribe.Token}}/{{.Unsubscribe.Recipient}}">{{.Unsubscribe.ContentType}}</a> notifications /
    {{end}}
    Unsubscribe from <a href="{{.Uri}}/Unsubscribe/{{.Unsubscribe.Token}}/{{.Unsubscribe.Recipient}}/all">all</a> emails from Koding.
`
