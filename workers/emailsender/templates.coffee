
{argv}      = require 'optimist'
{uri}       = require('koding-config-manager').load("main.#{argv.c}")
dateFormat  = require 'dateformat'

link      = (addr, text)   ->
  """<a href="#{addr}" #{Templates.linkStyle}>#{text}</a>"""

unsubscribeText = (unsubscribeId, suffix)->
  return ''  unless unsubscribeId

  l = link "#{uri.address}/Unsubscribe/#{unsubscribeId}/email", 'Unsubscribe'
  "#{l} if you do not want to receive this.#{suffix}"

Templates =

  linkStyle    : """ style="text-decoration:none; color:#ff9200;" """
  textTemplate : (content, unsubscribeId)->
    """
     Hello,

     #{content}

     #{unsubscribeText unsubscribeId, "\n"}Koding, Inc. 358 Brannan Street, San Francisco, CA 94107
    """

  htmlTemplate : (content, unsubscribeId)->

    currentDate  = dateFormat Date.now(), "mmm dd"
    activityTime = dateFormat Date.now(), "HH:MM"

    """
      <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
        "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html>
        <head><title>[Koding]</title></head>
        <body style="margin: 10px;">
          <table style="font-size: 13px; font-family: 'Open Sans', sans-serif;
                        height:100%; color: #666; width:100%;" cellspacing="0">

            <!-- HEADER -->
            <tr>
              <td style="width: 10px; text-align:right; border-right: 1px
                         solid #CCC; padding-right:10px; vertical-align:top;">
                <!-- Koding Logo with pure table -->
                <table width="28px" height="38px" style="height:38px; border:none; font-size:0px; " cellspacing="2">
                  <tr><td height="19%" style="height:19%; background-color:#FE6E00;" colspan="3">&nbsp;</td></tr>
                  <tr><td height="10%" style="height:10%; background-color:#403A32;" colspan="3">&nbsp;</td></tr>
                  <tr>
                      <td height="10%" style="height:10%; background-color:#403A32; width: 80%;" colspan="2">&nbsp;</td>
                      <td height="10%" style="height:10%; background-color:white; width: 20%;">&nbsp;</td>
                  </tr>
                  <tr><td height="10%" style="height:10%; background-color:#403A32;" colspan="3">&nbsp;</td></tr>
                  <tr><td height="10%" style="height:10%; background-color:#403A32;" colspan="3">&nbsp;</td></tr>
                  <tr>
                      <td height="10%" style="height:10%; background-color:#403A32; width: 80%;">&nbsp;</td>
                      <td height="10%" style="height:10%; background-color:white; width: 20%;" colspan="2">&nbsp;</td>
                  </tr>
                </table><br/>
              </td>
              <td style="padding: 6px 0 0 10px; padding-bottom:20px; margin-top: 0;">
                <p>#{content}</p>
              </td>
              <td style="text-align:center; width:90px; vertical-align:top;">
                <p style="font-size: 11px; color: #999;
                          padding: 0 0 2px 0; margin-top: 4px;">#{currentDate}</p>
              </td>
            </tr>

            <!-- CONTENT
            <tr style="vertical-align:top; background-color:white; color: #282623;">
              <td style="width: 10px; text-align:right; border-right: 1px solid #CCC;
                         color: #999; font-size:11px; line-height: 28px;
                         padding-right:10px;">#{activityTime}</td>
              <td style="padding-left: 10px; color: #666; " colspan="2">
                  #{content}
              </td>
            </tr> -->

            <!-- FOOTER -->
            <tr height="90%" style="height: 90%; ">
              <td style="width: 15px; border-right: 1px solid #CCC;"></td>
              <td height="40px" style="height:40px; padding-left: 10px;" colspan="2"></td>
            </tr>
            <tr style="font-size:11px; height: 30px; color: #999;">
              <td style="border-right: 1px solid #CCC; text-align:right;
                         padding-right:10px;"></td>
              <td style="padding-left: 10px;" colspan="2">
                #{unsubscribeText unsubscribeId, "<br/>"}#{link "https://koding.com", "Koding"}, Inc. 358 Brannan Street, San Francisco, CA 94107
              </td>
            </tr>
          </table>
        </body>
      </html>
    """

module.exports = Templates
