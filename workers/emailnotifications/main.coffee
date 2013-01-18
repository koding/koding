
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
                <p>
                  #{m.realContent.body}
                </p>
              <hr/>
            """
  switch m.event
    when 'LikeIsAdded'
      action = "liked your"
    when 'PrivateMessageSent'
      action = "sent you a"
    when 'ReplyIsAdded'
      if m.realContent.origin?._id is m.receiver._id
        action = "commented on your"
      else
        action = "also commented on"
        # FIXME GG Implement the details
        # if m.realContent.origin?._id is m.sender._id
        #   action = "#{action} own"

  """
    <p>
      Hi #{m.receiver.profile.firstName},
    </p>

    <p><a href="https://koding.com/#{m.sender.profile.nickname}">#{m.sender.profile.firstName} #{m.sender.profile.lastName}</a> #{action} #{m.contentLink}.</p>

    #{preview}

    <br /> -- <br />
    Management
  """

flags =
  comment           :
    template        : commonTemplate
  likeActivities    :
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
          if relatedContent.slug? or constructorName in ['JReview']
            callback null, contentTypeLinkMap(relatedContent.slug)[type]
          else
            constructor = \
              Base.constructors[relatedContent.bongo_.constructorName]
            constructor.fetchRelated? relatedContent._id, (err, content)->
              if err then callback err
              else
                callback null, contentTypeLinkMap(content.slug)[type]

  {JAccount, JEmailNotificationGG} = worker.models

  {event}     = notification.data
  contentType = notification.activity.subject.constructorName

  # Fetch Receiver
  JAccount.one {_id:notification.receiver.id}, (err, receiver)->
    if err then callback err
    else
      # Fetch Receiver E-Mail choices
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
            # Fetch Sender
            JAccount.one {_id:notification.sender}, (err, sender)->
              if err then callback err
              else
                # Fetch Subject Content
                fetchSubjectContent notification.activity, \
                (err, subjectContent)->
                  if err then callback err
                  else
                    realContent = subjectContent
                    # Create object which we pass to template later
                    details = {sender, receiver, event, email, key, \
                               subjectContent, realContent, notification}
                    # Fetch Subject Content-Link
                    # If Subject is a secondary level content like JComment
                    # we need to get its parent's slug to show link correctly
                    fetchSubjectContentLink subjectContent, contentType, \
                    (err, link)->
                      if err then callback err
                      else
                        details.contentLink = link
                        if event is 'ReplyIsAdded'
                          # Fetch RealContent
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