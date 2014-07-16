
{argv}      = require 'optimist'
{uri}       = require('koding-config-manager').load("main.#{argv.c}")
dateFormat  = require 'dateformat'
htmlify     = require 'koding-htmlify'
juice       = require 'juice'
swig        = require 'swig'

flags =
  comment                 :
    definition            : "comment"
  likeActivities          :
    definition            : "like"
  followActions           :
    definition            : "follow"
  privateMessage          :
    definition            : "private message"
  groupInvite             :
    definition            : "group invite"
    fullDefinition        : "has invited you to"
  groupRequest            :
    'ApprovalRequested'   :
      definition          : "group access request"
      fullDefinition      : "has requested access to"
    'InvitationRequested' :
      definition          : "group invitation request"
      fullDefinition      : "has requested invitation to"
  groupApproved           :
    definition            : "group access approval"
    fullDefinition        : "has approved your access request to"
  groupLeft               :
    definition            : "group left"
    fullDefinition        : "has left your group"
  groupJoined             :
    definition            : "group join"
    fullDefinition        : "has joined your group"

link      = (addr, text)   ->
  """<a href="#{addr}" #{Templates.linkStyle}>#{text}</a>"""
gravatar  = (m, size = 20) ->
  """<img width="#{size}px" height="#{size}px" style="border:none; margin-right:8px; float:left; margin-top:3px;"
          src="https://gravatar.com/avatar/#{m.sender.profile?.hash}?size=#{size}&d=https%3A%2F%2Fapi.koding.com%2Fimages%2Fdefaultavatar%2Fdefault.avatar.#{size}.png" />"""

Templates =

  render : (tpl, m, data) ->
    template = swig.compileFile "#{__dirname}/templates/"+tpl;
    data = _.extend {
      m: m,
      currentDate: dateFormat m.notification.dateIssued, "mmm dd"
      turnOffLink: "#{uri.address}/Unsubscribe/#{m.notification.unsubscribeId}"
    }, data

    template(data)

  linkStyle    : """ style="text-decoration:none; color:#1AAF5D;" """
  mainTemplate : (m, content, footer, description)->

    description ?= ''
    currentDate  = dateFormat m.notification.dateIssued, "mmm dd"
    turnOffLink  = "#{uri.address}/Unsubscribe/#{m.notification.unsubscribeId}"

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
              <td style="width: 58px; text-align:right; border-right: 1px
                         solid #CCC; margin-left:12px; vertical-align:top;">
                <!-- Koding Logo with pure table -->
                <table width="40px" height="40px" style="margin-left:12px; width:40px; text-align:right; height:40px; border:none; font-size:0px; background-color:#1AAF5D; padding:9px;" cellspacing="2" cellpadding="2">
                  <tr>
                      <td height="1px" style="max-height:1px;height:1px; background-color:white;" colspan="3">&nbsp;</td>
                  </tr>
                  <tr>
                      <td height="1px" style="max-height:1px;height:1px; background-color:white;  width: 75%;" >&nbsp;</td>
                      <td height="1px" style="max-height:1px;height:1px; background-color:#1AAF5D; width: 25%;" colspan="2">&nbsp;</td>
                  </tr>
                  <tr>
                      <td height="1px" style="max-height:1px;height:1px; background-color:white;" colspan="3">&nbsp;</td>
                  </tr>
                </table><br/>
              </td>
              <td style="padding: 6px 0 0 10px; padding-bottom:20px; margin-top: 0;">
                <h2 style="margin-top:0; ">Hello #{m.receiver.profile.firstName},</h2>
                <p>#{description}</p>
              </td>
              <td style="text-align:center; width:90px; vertical-align:top;">
                <p style="font-size: 11px; color: #999;
                          padding: 0 0 2px 0; margin-top: 4px;">#{currentDate}</p>
              </td>
            </tr>
            #{content}
            #{footer}
          </table>
        </body>
      </html>
    """

  footerTemplate : (turnOffLink)->
    """
    <!-- FOOTER -->
    <tr height="90%" style="height: 90%; ">
      <td style="width: 15px; border-right: 1px solid #CCC;"></td>
      <td height="40px" style="height:40px; padding-left: 10px;" colspan="2"></td>
    </tr>
    <tr style="font-size:11px; height: 30px; color: #999;">
      <td style="border-right: 1px solid #CCC; text-align:right;
                 padding-right:10px;"></td>
      <td style="padding-left: 10px;" colspan="2">
        #{turnOffLink}<br/>
        #{link "https://koding.com", "Koding"}, Inc. 358 Brannan, San Francisco, CA 94107
      </td>
    </tr>
    """

  singleEvent : (m)->
    action       = ''
    group        = ''

    getGroupLink = ->
      if m.group and m.group.slug isnt "koding"
        "in <a href='#{uri.address}/#{m.group.slug}' #{Templates.linkStyle}>#{m.group.title}</a> group"
      else
        ""

    if m.sender.profile?
      sender     = link "#{uri.address}/#{m.sender.profile.nickname}", \
                        "#{m.sender.profile.firstName} #{m.sender.profile.lastName}"
    else
      sender     = m.sender
    avatar       = gravatar m
    activityTime = dateFormat m.notification.dateIssued, "HH:MM"
    preview      = ''
    if m.realContent?.body
      preview    = """<div style="padding:10px; margin-left:28px; color:#777;
                                  margin-bottom:6px; margin-top: 4px;
                                  font-size:12px; background-color:#F8F8F8;
                                  border-radius:4px;">
                      #{m.realContent?.body}</div>"""

    switch m.event
      when 'FollowHappened'
        action = "started following you."
        m.contentLink = ''
        preview = ''
      when 'LikeIsAdded'
        action = "liked your"
        group  = getGroupLink()
      when 'PrivateMessageSent'
        action = "sent you a"
      when 'ReplyIsAdded'
        if m.receiver.getId().equals m.subjectContent.data.originId
          action = "commented on your"
        else
          action = "also commented on"

        group = getGroupLink()
          # FIXME GG Implement the details
          # if m.realContent.origin?._id is m.sender._id
          #   action = "#{action} own"
      when 'Invited'
        action  = 'has invited you to join the group'
        if m.notification.activity.message # we want to customize the whole message
          sender = htmlify m.notification.activity.message, linkStyle:Templates.linkStyle
          sender = sender.replace /#INVITER#/g, "#{m.sender.profile.firstName} #{m.sender.profile.lastName}"
          sender = sender.replace /#URL#/g, "<a href='#{uri.address}/#{m.realContent.slug}' #{Templates.linkStyle}>#{uri.address}/#{m.realContent.slug}</a>"
          action        = ''
          preview       = ''
          m.contentLink = ''
      when 'ApprovalRequested'
        action  = 'has requested access to the group'
        preview = ''
      when 'InvitationRequested'
        action  = 'has requested invitation to the group'
        preview = ''
      when 'Approved'
        action  = 'has approved your access request to the group'
        preview = ''
      when 'GroupJoined'
        action  = 'has joined your group'
        preview = ''
      when 'GroupLeft'
        action  = 'has left your group'
        preview = ''

    """
      <tr style="vertical-align:top; background-color:white; color: #282623;">
        <td style="width: 40px; text-align:right; border-right: 1px solid #CCC;
                   color: #999; font-size:11px; line-height: 28px;
                   padding-right:10px;"><a href='#'
                   style='text-decoration:none; color:#999;pointer-event:none'>
                   #{activityTime}</a></td>
        <td style="padding-left: 10px; color: #666; " colspan="2">
            #{avatar}
            <div style="line-height: 20px; padding-left:28px; padding-top:4px;">
              #{sender} #{action} #{m.contentLink} #{group}
            </div>
            #{preview}
        </td>
      </tr>
    """

  instantMail  : (m)->
    eventName   = flags[m.notification.eventFlag].definition
    turnOffLink = "#{uri.address}/Unsubscribe/#{m.notification.unsubscribeId}/#{encodeURIComponent m.email}"
    turnOffAllURL = link turnOffLink+"/all","all"
    turnOffSpecificType = link turnOffLink, eventName
    turnOffLink = """Unsubscribe from #{turnOffSpecificType} notifications / Unsubscribe from #{turnOffAllURL} emails from Koding."""

    Templates.mainTemplate m, \
      Templates.singleEvent(m), Templates.footerTemplate turnOffLink

  dailyMail    : (m, content)->
    Templates.render "daily", m, {
      turnOffLink:  "#{uri.address}/Unsubscribe/#{m.notification.unsubscribeId}/#{encodeURIComponent m.email}",
      content: content
    }

  commonHeader : (m)->
    eventFlag = flags[m.notification.eventFlag][m.event] ? flags[m.notification.eventFlag]

    if eventFlag.fullDefinition?
      if m.sender.profile?
        sender = "#{m.sender.profile.firstName} #{m.sender.profile.lastName}"
      else
        sender = m.sender
      contentName = m.realContent?.title
      sentence = eventFlag.fullDefinition
      return "#{sender} #{sentence} #{contentName}!"
    eventName   = eventFlag.definition
    header = """You have a new #{if eventName is "follow" then "follower" else eventName}"""
    header = "#{header} in #{m.group?.title} group"  if m.group and m.group.slug isnt "koding"
    return header

  dailyHeader  : (m)->
    currentDate  = dateFormat m.notification.dateIssued, "mmm dd"
    return """Your Koding Activity for today: #{currentDate}"""

module.exports = Templates
