
{argv}    = require 'optimist'
{CronJob} = require 'cron'
Bongo     = require 'bongo'
Broker    = require 'broker'
{Base}    = Bongo
Emailer   = require '../social/lib/social/emailer'
template  = require './templates'

{mq, mongo, email, uri} = require('koding-config-manager').load("main.#{argv.c}")

broker = new Broker mq

worker = new Bongo {
  mongo
  mq     : broker
  root   : __dirname
  models : '../social/lib/social/models'
}

log = ->
  console.log "[E-MAIL]", arguments...

log "E-Mail Notification Worker has started with PID #{process.pid}"

flags =
  comment           :
    template        : template.instantMail
    definition      : "comments"
  likeActivities    :
    template        : template.instantMail
    definition      : "activity likes"
  followActions     :
    template        : template.instantMail
    definition      : "following states"
  privateMessage    :
    template        : template.instantMail
    definition      : "private messages"

sendEmail = (details)->
  {notification} = details
  # log "MAIL", flags[details.key].template details

  Emailer.send
    To        : "gokmen+testas@koding.com" # details.email
    Subject   : template.commonHeader details
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
    pre = "<a href='#{uri.address}/Activity/#{link}' #{template.linkStyle}>"

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
    callback null, "<a href='https://koding.com/Inbox' #{template.linkStyle}>private message</a>"
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

prepareEmail = (notification, cb)->

  {JAccount, JEmailNotificationGG} = worker.models

  {event}     = notification.data
  if event is 'FollowHappened'
    contentType = 'JAccount'
  else
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
      , (err, state, key, email)->
        if err
          console.error "Could not load user record"
          callback err
        else
          if state isnt 'on'
            log 'User disabled e-mails, ignored for now.'
            notification.update $set: status: 'postponed', (err)->
              console.error err if err
          else
            # log "Trying to send it... to...", email
            # Fetch Sender
            JAccount.one {_id:notification.sender}, (err, sender)->
              if err then callback err
              else
                details = {sender, receiver, event, email, key, notification}
                if event is 'FollowHappened'
                  cb details
                else
                  # Fetch Subject Content
                  fetchSubjectContent notification.activity, \
                  (err, subjectContent)->
                    if err then callback err
                    else
                      realContent = subjectContent
                      # Create object which we pass to template later
                      details.subjectContent = subjectContent
                      details.realContent    = realContent
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
                                cb details
                          else
                            cb details

instantEmails = ->
  {JEmailNotificationGG} = worker.models
  # log "Checking for waiting queue..."

  JEmailNotificationGG.some {status: "queued"}, {limit:100}, (err, emails)->
    if err
      log "Could not load email queue!"
    else
      if emails.length > 0
        log "There are #{emails.length} mail in queue."
        for email in emails
          prepareEmail email, sendEmail
      # else
      #   log "E-Mail queue is empty. Yay."

instantEmailsCron = new CronJob email.notificationCronInstant, instantEmails
instantEmailsCron.start()