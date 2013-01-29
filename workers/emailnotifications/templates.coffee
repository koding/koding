
{argv}      = require 'optimist'
{uri}       = require('koding-config-manager').load("main.#{argv.c}")
dateFormat  = require 'dateformat'

flags =
  comment           :
    definition      : "comments"
  likeActivities    :
    definition      : "activity likes"
  followActions     :
    definition      : "following states"
  privateMessage    :
    definition      : "private messages"

link      = (addr, text)   -> """<a href="#{addr}" #{Templates.linkStyle}>#{text}</a>"""
gravatar  = (m, size = 20) -> """<img style="margin-right:8px; float:left;" src="https://gravatar.com/avatar/#{m.sender.profile.hash}?size=#{size}&d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.#{size}.png" />"""

Templates =

  linkStyle    : """ style="text-decoration:none; color:#ff9200;" """
  mainTemplate : (m, content)->

    description  = ''
    eventName    = flags[m.notification.eventFlag].definition
    turnOffLink  = "#{uri.address}/Unsubscribe/#{m.notification.unsubscribeId}"
    currentDate  = dateFormat m.notification.dateIssued, "mmm dd"

    """
      <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">
        <html>
        <head><title>[Koding]</title></head>
        <body style="margin: 10px;">
          <table style="font-size: 13px; font-family: 'Open Sans', sans-serif; height:100%; color: #666; width:100%;" cellspacing="0" >
            <!-- HEADER -->
            <tr style="vertical-align:top;">
              <td style="width: 10px; text-align:right; border-right: 1px solid #CCC; padding-right:10px;"><img alt="Koding" src="https://gokmen.koding.com/images/kd-logo.png" /><br/></td>
              <td style="padding: 6px 0 0 10px; padding-bottom:20px; ">
                <h2>Hello #{m.receiver.profile.firstName},</h2>
                <p>#{description}</p>
              </td>
              <td style="text-align:center; width:90px; ">
                <p style="font-size: 11px;  color: #999; padding: 13px 0 2px 0;">#{currentDate}</p>
              </td>
            </tr>

            #{content}

            <!-- FOOTER -->
            <tr style="height: 90%; ">
                <td style="width: 15px; border-right: 1px solid #CCC;"></td>
                <td style="height:30px; padding-left: 10px;" colspan="2"></td>
            </tr>
            <tr style="font-size:11px; height: 30px; color: #999;">
                <td style="border-right: 1px solid #CCC; text-align:right; padding-right:10px;">
                  <img alt="Help" src="https://gokmen.koding.com/images/question-mark.png" />
                </td>
                <td style="padding-left: 10px;" colspan="2">
                  You can turn off e-mail notifications for #{link turnOffLink, eventName} or #{link "#{turnOffLink}/all", "any kind of e-mails"}</a>.
                </td>
            </tr>
          </table>
        </body>
      </html>
    """

  singleEvent : (m)->

    action       = ''
    sender       = link "#{uri.address}/#{m.sender.profile.nickname}", "#{m.sender.profile.firstName} #{m.sender.profile.lastName}"
    avatar       = gravatar m
    activityTime = dateFormat m.notification.dateIssued, "HH:MM"
    preview      = """<div style="margin-top:14px; color:#777; font-size:12px; ">#{m.realContent?.body}</div>"""

    switch m.event
      when 'FollowHappened'
        action = "is started to following you"
        m.contentLink = ''
        preview = ''
      when 'LikeIsAdded'
        action = "liked your"
      when 'PrivateMessageSent'
        action = "sent you a"
      when 'ReplyIsAdded'
        if m.receiver.getId().equals m.subjectContent.data.originId
          action = "commented on your"
        else
          action = "also commented on"
          # FIXME GG Implement the details
          # if m.realContent.origin?._id is m.sender._id
          #   action = "#{action} own"

    """
      <tr style="vertical-align:top; background-color:white; color: #282623;">
        <td style="width: 10px; text-align:right; border-right: 1px solid #CCC; color: #999; font-size:11px; line-height: 28px; padding-right:10px;">#{activityTime}</td>
        <td style="padding-left: 10px; color: #666; " colspan="2">
            #{avatar}
            <div style="line-height: 28px;">#{sender} #{action} #{m.contentLink}</div>
            #{preview}
        </td>
      </tr>
    """

  instantMail  : (m)-> Templates.mainTemplate m, Templates.singleEvent m
  commonHeader : (m)-> """[Koding Bot] A new notification"""

module.exports = Templates