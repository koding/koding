package templates

const Layout = `
<html>
	<head>
	  <meta charset="UTF-8">
	  <title>[Koding] {{.Title}}</title>
	</head>
	<body style="background: #eeeeee; margin: 0; padding:22px; font-family: 'Helvetica Neue', Helvetica, sans-serif;">
		<style>
	    .m-footer a {
	      color: #bababa;
	    }
  	</style>
  	<div style="background: #fff; max-width: 600px; margin: 0 auto;">
	    <div style="padding: 0% 20px 1%; background: #eeeeee; text-align:center;">
	      <img src="https://koding.s3.amazonaws.com/images/email-logo.png" alt="Koding" width="142px" style="opacity: 0.5;"/>
	    </div>

      <div style="border-top: 1px solid #dcdcdc; padding: 22px; font-size: 14px; color: #353535; line-height: 18px;">
        <h4 style="color: #18ad5c; font-size: 18px; font-weight: 600; display: block; margin: 10px 0;">Hi {{.FirstName}},</h4>
  	    {{.Body}}
      </div>

      <!-- FOOTER -->
      <div class="m-footer" style="background: #fafafa; border-top: 1px solid #dcdcdc; padding: 10px; font-size: 12px; color: #a4a4a4; line-height: 18px;">
      {{if .ShowLink }}
        Unsubscribe from <a href="{{.Hostname}}/Unsubscribe/{{.Token}}/{{.RecipientEmail}}">{{.ContentType}}</a> notifications /
      {{end}}
        Unsubscribe from <a href="{{.Hostname}}/Unsubscribe/{{.Token}}/{{.RecipientEmail}}/all">all</a> emails from Koding.
        <br/>
        <a href="{{.Hostname}}">Koding</a>, Inc. 358 Brannan, San Francisco, CA 94107
      </div>
    </div>
	</body>
</html>
`
