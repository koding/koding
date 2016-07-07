// Package sender provides an API for mail sending operations
package emailsender

var TemplateTeamInvite = `<html>
  <head>
    <title></title>
    <style type="text/css">
     a {
        color:#1aaf5b;
        text-decoration:none;
     }
    .btn {
        -webkit-border-radius: 5;
        -moz-border-radius: 5;
        border-radius: 5px;
        font-family: HelveticaNeue;
        color: #ffffff;
        font-weight:400;
        background: #1aaf5b;
        padding: 7px 12px 7px 12px;
        text-decoration: none;
    }
    .btn:hover {
        text-decoration: none;
    }
    .p {
        line-height:23px;
        margin:  0px;
        padding: 0px;
        color: #565656;
    }
    .td {
        vertical-align:top;
    }
    </style>
    <meta charset="UTF-8" />
  </head>
  <body style="background: #fafafa;">
    <div style="background: #fafafa; color: #3c3c3c; font-family: 'HelveticaNeue', 'Helvetica Neue', Helvetica, Arial, 'Lucida Grande', sans-serif; font-size: 16px; padding: 40px 0;">
      <div style="margin: 0 auto; max-width: 700px;">
        <div style="margin: 0 0 31px; text-align: center;">
          <img alt="Koding logo" src="http://cdn2.hubspot.net/hubfs/1593820/logo_emailHeader.png" height="36" />
        </div>
        <div>
          <div style="color: #565656; background: #fff; border: 1px solid #e0e0e0; border-radius: 3px; padding: 35px 45px 41px; max-width: 575px; margin-right: auto; margin-left: auto;">
            <style>
body {
  font-size: 12px;
}
body .wysiwyg-text-align-center {
  text-align: center;
}
body .wysiwyg-text-align-left {
  text-align: left;
}
body .wysiwyg-text-align-right {
  text-align: right;
}
body .wysiwyg-font-size-larger {
  font-size: 36px;
}
body .wysiwyg-font-size-large {
  font-size: 30px;
}
body .wysiwyg-font-size-medium {
  font-size: 24px;
}
body .wysiwyg-font-size-small {
  font-size: 16px;
}
body .wysiwyg-font-size-smaller {
  font-size: 12px;
}
</style>

<div style="font-family:'HelveticaNeue-Light', 'Helvetica Neue Light', 'Helvetica Neue', Helvetica, Arial, 'Lucida Grande', sans-serif;font-weight:300;">
    <p style="text-align:center;font-size:14px;margin-bottom:0;color:#565656;">
        You’re invited to try
    </p>
    <table style="width:100%;text-align:center;">
        <tbody>
        <tr>
            <td>
                <span style="color:#565656;font-size:28px;display:block;margin-top:10px;font-weight:600;">Koding For Teams!</span>
            </td>
        </tr>
        </tbody>
    </table>
    <p style="color:#565656;font-size:14px;margin:40px 0 50px;line-height:21px;">Hi there,
        <br /><br />
        We’d like to invite you to try Koding For Teams (Beta)!
        <br /><br />
        Your team will have access to new features that help you collaborate and get set up faster. Pair program in the cloud or setup a new hire's dev-environment automatically; then use all that timed saved however you want.
    </p>
    <div style="width:100%;text-align:center;">
        <a href="{{ .Link }}" style="width:auto;padding:10px 45px;background:#1aaf5b;font-size:14px;text-decoration:none;color:white;border-radius:3px;line-height:25px;display:inline-block;letter-spacing:1px;" target="_blank">
        GET STARTED
        </a>
    </div>
    <p style="font-style:italic;text-align:center;margin-top:35px;color:#565656;font-weight:100;font-size:15px;letter-spacing:0.6px">
        Features you'll only find on <b style="font-weight:400;">Koding For Teams</b>:
    </p>
    <table style="font-size:14px;color:#565656;font-weight:200;margin-top:40px;width:100%">
        <tbody>
        <tr>
            <td style="width:30%;text-align:center;line-height:20px;">
                <div style="height:60px">
                    <img src="https://koding-email-images.s3.amazonaws.com/v1/teams/creation/clock.png" width="38" height="40">
                </div>
                <span style="height:80px;display:block;">Onboard In Minutes<br> (not weeks)</span>
            </td>
            <td style="width:30%;text-align:center;line-height:20px;">
                <div style="height:60px">
                    <img src="https://koding-email-images.s3.amazonaws.com/v1/teams/creation/windows.png" width="40" height="35">
                </div>
                <span style="height:80px;display:block;">Use IDEs / Terminals<br> you know &amp; love</span>
            </td>
            <td style="width:30%;text-align:center;line-height:20px;">
                <div style="height:60px">
                    <img src="https://koding-email-images.s3.amazonaws.com/v1/teams/creation/pair.png" width="44" height="38">
                </div>
                <span style="height:80px;display:block;">Pair Program<br> with chat &amp; video</span>
            </td>
            </tr>
        </tbody>
    </table>
</div>

            <p style="line-height: 23px; margin: 0; margin-top: 30px; padding: 0;">
                <span style="color:#565656;font-size:14px;font-family:'HelveticaNeue-Light', 'Helvetica Neue Light', 'Helvetica Neue', Helvetica, Arial, 'Lucida Grande', sans-serif;font-weight:300;">&#58; &#62;<br />Team Koding</span>
            </p>
          </div>
        </div>
        <div style="color: #565656; font-size: 12px; line-height: 24px; text-align: center; margin-top:35px;">
          <a style="color: #1aaf5b; text-decoration: none;" href="mailto:support@koding.com">Contact us</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
          <a style="color: #1aaf5b; text-decoration: none;" href="{{ .LinkUnsubscribe }}">Unsubscribe</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
          <a style="color: #1aaf5b; text-decoration: none;" href="https://koding.com/docs" title="koding.com">F.A.Q.</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
          <a style="color: #1aaf5b; text-decoration: none;" href="https://koding.com/blog" title="Our blog">Blog</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
          <a style="color: #1aaf5b; text-decoration: none;" href="http://twitter.com/koding" title="Follow us on twitter">Twitter</a>&nbsp;&nbsp;&bull;&nbsp;&nbsp;
          <a style="color: #1aaf5b; text-decoration: none;" href="http://facebook.com/koding" title="Follow us on facebook">Facebook</a>
          <br />
          Made in San Francisco:  <a style="color: #565656; text-decoration: none;" href="https://www.google.com/maps/place/Koding/@37.7809744,-122.3958986,17z/data=!3m1!4b1!4m2!3m1!1s0x8085807890964461:0x19565028803b8b47">358 Brannan Street</a>.
          <br />
          <a href="https://jobs.lever.co/koding" target="_blank" style="margin: 25px auto; display: inline-block;">
            <span style="float: left; width: 12px; height: 2px; background: #BCBCBC; margin-top: 10px;"></span>
            <div style="color: #4DA0FF; font-weight: 600; margin: 0 15px; font-family: 'HelveticaNeue', 'Helvetica Neue', Helvetica, Arial, 'Lucida Grande'; float: left; margin: 0 15px; ">
              <img src="https://koding-email-images.s3.amazonaws.com/v1/announcement.png" alt="Koding" width="16" height="16" style="margin-right: 7px; margin-top: 5px; float: left;" />
              <span style="float: left;">We're Hiring!</span>
            </div>
            <span style="float: right; width: 12px; height: 2px; background: #BCBCBC; margin-top: 10px;"></span>
          </a>
        </div>
      </div>
    </div>
  </body>
</html>`

var TemplateTeamInviteText = `Hi {{ .UserID }},

We’d like to invite you to try Koding For Teams (Beta)!

Your team will have access to new features that help you collaborate and get set up faster. Pair program in the cloud or setup a new hire's dev-environment automatically; then use all that timed saved however you want.

Get started here:

{{ .Link }}

Features you'll only find on Koding For Teams:

* Onboard In Minutes (not weeks)
* Use IDEs / Terminals you know & love
* Pair Program with chat & video

: >
Team Koding`
