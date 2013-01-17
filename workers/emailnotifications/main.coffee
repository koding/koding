
{argv}    = require 'optimist'
{CronJob} = require 'cron'
Bongo     = require 'bongo'
Broker    = require 'broker'
{Base}    = Bongo
Emailer   = require '../social/lib/social/emailer'

{mq, mongo, email} = require('koding-config-manager').load("main.#{argv.c}")

broker = new Broker mq

worker = new Bongo {
  mongo
  mq     : broker
  root   : __dirname
  models : '../social/lib/social/models'
}

log = ->
  console.log "[E-MAIL NOTIFIER]", arguments...

log "Koding E-Mail Notification Worker has started with PID #{process.pid}"

commonHeader     = (m)-> """[Koding Bot] A new notification"""
commonTemplate   = (m)->
  action  = ''
  preview = """

              <hr/>
                #{m.realContent.body}
              <hr/>

            """
  switch m.event
    when 'LikeIsAdded'
      action = "liked your"
      preview = ''
    when 'PrivateMessageSent'
      action = "sent you a"
    when 'ReplyIsAdded'
      action  = "commented on your"

  """
    Hi #{m.receiver.profile.firstName},

    <a href="https://koding.com/#{m.sender.profile.nickname}">#{m.sender.profile.firstName} #{m.sender.profile.lastName}</a> #{action} #{m.contentLink}.
    #{preview}

    --
    Management
  """

flags =
  comment           :
    template        : commonTemplate
  likeActivities    :
    template        : commonTemplate
  likeComments      :
    template        : commonTemplate
  followActions     :
    template        : commonTemplate
  privateMessage    :
    template        : commonTemplate

prepareAndSendEmail = (notification)->

  sendEmail = (details)->
    {notification} = details
    # log "MAIL", flags[details.key].template details

    Emailer.send
      To        : details.email
      Subject   : commonHeader details
      HtmlBody  : flags[details.key].template details
    , (err, status)->
      log "An error occured: #{err}" if err
      notification.update $set: status: 'attempted', (err)->
        console.error err if err

  fetchSubjectContent = (contents, callback)->
    {constructorName} = contents.subject
    constructor       = Base.constructors[constructorName]
    constructor.one {_id:contents.subject.id}, (err, res)->
      if err then console.error err
      callback err, res

  fetchContent = (content, callback)->
    {constructorName} = content
    unless constructorName
      callback new KodingError 'Action type wrong.'
    else
      constructor     = Base.constructors[constructorName]
      {id}            = content
      constructor.one {_id:id}, (err, res)->
        if err then console.error err
        callback err, res

  fetchSubjectContentLink = (content, type, callback)->

    contentTypeLinkMap = (link)->
      pre = "<a href='https://koding.com/Activity/#{link}'>"

      JReview           : "#{pre}review</a>"
      JComment          : "#{pre}comment</a>"
      JOpinion          : "#{pre}opinion</a>"
      JCodeSnip         : "#{pre}code snippet</a>"
      JTutorial         : "#{pre}tutorial</a>"
      JDiscussion       : "#{pre}discussion</a>"
      JLinkActivity     : "#{pre}link</a>"
      JStatusUpdate     : "#{pre}status update</a>"
      JPrivateMessage   : "#{pre}private message</a>"
      JQuestionActivity : "#{pre}question</a>"

    if type is 'JPrivateMessage'
      callback null, "<a href='https://koding.com/Inbox'>private message</a>"
    else if content.slug
      callback null, contentTypeLinkMap(content.slug)[type]
    else
      {constructorName} = content.bongo_
      constructor = Base.constructors[constructorName]
      constructor.fetchRelated? content._id, (err, relatedContent)->
        if err then callback err
        else
          unless relatedContent.slug?
            constructor = \
              Base.constructors[relatedContent.bongo_.constructorName]
            constructor.fetchRelated? relatedContent._id, (err, content)->
              if err then callback err
              else
                callback null, contentTypeLinkMap(content.slug)[type]
          else
            callback null, contentTypeLinkMap(relatedContent.slug)[type]

  {JAccount, JEmailNotificationGG} = worker.models

  {event}     = notification.data
  contentType = notification.activity.subject.constructorName

  JAccount.one {_id:notification.receiver.id}, (err, receiver)->
    if err then callback err
    else
      JEmailNotificationGG.checkEmailChoice
        event       : event
        contentType : contentType
        username    : receiver.profile.nickname
      , (err, state, email, key)->
        if err
          console.error "Could not load user record"
          callback err
        else
          if state not in ['instant', 'daily']
            log 'User disabled e-mails, ignored for now.'
            notification.update $set: status: 'postponed', (err)->
              console.error err if err
          else
            # log "Trying to send it... to...", email
            JAccount.one {_id:notification.sender}, (err, sender)->
              if err then callback err
              else
                fetchSubjectContent notification.activity, \
                (err, subjectContent)->
                  if err then callback err
                  else
                    realContent = subjectContent
                    details = {sender, receiver, event, email, key, \
                               subjectContent, realContent, notification}
                    fetchSubjectContentLink subjectContent, contentType, \
                    (err, link)->
                      if err then callback err
                      else
                        details.contentLink = link
                        if event is 'ReplyIsAdded'
                          fetchContent notification.activity.content, \
                          (err, content)->
                            if err then callback err
                            else
                              details.realContent = content
                              sendEmail details
                        else
                          sendEmail details

job = new CronJob email.notificationCron, ->

  {JEmailNotificationGG} = worker.models
  # log "Checking for waiting queue..."

  JEmailNotificationGG.some {status: "queued"}, {limit:10}, (err, emails)->
    if err
      log "Could not load email queue!"
    else
      if emails.length > 0
        log "There are #{emails.length} mail in queue."
        for email in emails
          prepareAndSendEmail email
      # else
      #   log "E-Mail queue is empty. Yay."

job.start()