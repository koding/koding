package templates

const Layout = `
<html>
	<head>
	  <meta charset="UTF-8">
	  <title>[Koding] {{.Title}}</title>
	</head>
	<body style="color: #656565; margin: 0; font-family: 'HelveticaNeue-Light', 'Helvetica Neue Light', Helvetica, Arial, 'Lucida Grande', sans-serif;">
		<style>
      a {
        text-decoration: none;
      }
      .post a, .footer a {
        color: #52A840;
      }
    </style>

  	<div style="background: #F5F5F5; padding: 40px 20px;">
	    <div style="margin: 0 auto; max-width: 676px;">
        <div style="text-align: left;">
          <a href="http://koding.com" title="koding.com">
            <img src="https://koding.s3.amazonaws.com/images/email-logo.png" alt="Koding" width="102px" height="25px">
          </a>
        </div>
        <p style="padding: 22px 0 28px; margin: 0; font-size: 14px; letter-spacing: 0.02em">
          <span style="color: #52A840; font-weight: bold; margin-bottom:7px; display: block">
            Hey {{.FirstName}},
          </span>
          {{.Information}}
        </p>
        {{.Body}}



        <!-- FOOTER -->
        <div class="footer" style="font-size: 12px; color: #9A9A9A; line-height: 15px; margin: 29px 0 0 0;">
          {{if .ShowLink }}
            Unsubscribe from <a href="{{.Hostname}}/Unsubscribe/{{.Token}}/{{.RecipientEmail}}" style="color: #61B351; font-weight: bold; text-decoration: none;">{{.ContentType}}</a> notifications /
          {{end}}
          Unsubscribe from <a href="{{.Hostname}}/Unsubscribe/{{.Token}}/{{.RecipientEmail}}/all" style="color: #61B351; font-weight: bold; text-decoration: none;">all</a> emails from Koding.
          For more detailed preferences, see your <a href="{{.Hostname}}/Account/Email" style="color: #61B351; font-weight: bold; text-decoration: none;">account page.</a>
        </div>

        <div style="height: 2px; background: #EAEAEA; margin: 29px 0 41px 0;"></div>

        <div style="text-align: center; font-size: 12px; color: #9A9A9A; line-height: 16px;">
          <a href="{{.Hostname}}" style="color: #9A9A9A; text-decoration: none;" title="Koding.com">Koding, Inc</a>
          •
          <a href="https://twitter.com/koding" title="Twitter" style="color: #9A9A9A; text-decoration: none;" title="Follow us on Twitter">
            Twitter
          </a>
          •
          <a href="https://www.facebook.com/koding" title="Facebook" style="color: #9A9A9A; text-decoration: none;" title="Follow us on Facebook">
            Facebook
          </a>
          <br>
          358 Brannan Street • San Francisco, CA • 94107
        </div>
      </div>
    </div>
	</body>
</html>
`
