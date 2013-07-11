# ~ GG

{argv}    = require 'optimist'
{CronJob} = require 'cron'
Bongo     = require 'bongo'
Broker    = require 'broker'
{Base}    = Bongo
{Relationship} = require 'jraphical'
Emailer   = require '../social/lib/social/emailer'
template  = require './templates'

{mq, mongo, email, emailWorker, uri} = \
  require('koding-config-manager').load("main.#{argv.c}")

mongo += '?auto_reconnect'

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
  comment              :
    template           : template.instantMail
    definition         : "comments"
  likeActivities       :
    template           : template.instantMail
    definition         : "likes"
  followActions        :
    template           : template.instantMail
    definition         : "follows"
  privateMessage       :
    template           : template.instantMail
    definition         : "private messages"
  groupInvite          :
    template           : template.instantMail
    definition         : "group invitation"
  groupRequest         :
    template           : template.instantMail
    definition         : "group membership request"
  groupApproved        :
    template           : template.instantMail
    definition         : "group membership request approved"

sendDailyEmail = (details, content)->
  unless content or details.email
    log "Content not found, notification postponed"
  else
    Emailer.send
      From      : 'Koding <hello@koding.com>'
      To        : emailWorker.forcedRecipient or details.email
      Subject   : template.dailyHeader details
      HtmlBody  : template.dailyMail details, content
    , (err, status)->
      log "An error occured: #{err}" if err
      log "Daily e-mail sent to #{details.email}"

sendInstantEmail = (details)->
  {notification} = details
  if details.realContent?.deletedAt? or not details.email?
    log "Content not found, notification postponed"
    notification.update $set: status: 'postponed', (err)->
      console.error if err
  else
    Emailer.send
      From      : 'Koding <hello@koding.com>'
      To        : emailWorker.forcedRecipient or details.email
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
  else if type is 'JGroup'
    callback null, "<a href='https://koding.com/#{content.slug}' #{template.linkStyle}>#{content.title}</a>"
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

prepareEmail = (notification, daily = no, cb, callback=->)->

  {JAccount, JMailNotification} = worker.models

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
      JMailNotification.checkEmailChoice
        event       : event
        contentType : contentType
        username    : receiver.profile.nickname
      , (err, state, key, email)->
        if err
          console.error "Could not load user record"
          callback err
        else
          if not daily and state isnt true
            log 'User disabled e-mails, ignored for now.'
            notification.update $set: status: 'postponed', (err)->
              console.error err if err
          else
            # Fetch Sender
            JAccount.one {_id:notification.sender}, (err, sender)->
              if err then callback err
              else
                # string usually email if sender is not a user
                sender ?= notification.senderEmail
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
  {JMailNotification} = worker.models
  JMailNotification.some {status: "queued"}, {limit:300}, (err, emails)->
    if err or not emails
      log "Could not load email queue!"
    else
      if emails.length > 0
        currentIds = [email._id for email in emails][0]
        JMailNotification.update {_id: $in: currentIds}, \
          {$set: status: 'sending'}, {multi: yes}, (err)->
          unless err
            log "Sending #{emails.length} e-mail(s)..."
            for email in emails
              prepareEmail email, no, sendInstantEmail, (err)->
                console.log err
          else
            log "An error occured: #{err}"

prepareDailyEmail = (emails, index, data, callback)->

  [callback, data] = [data, callback] unless callback
  data             = [] unless data

  if index < emails.length
    prepareEmail emails[index], yes, (content)->
      data.push content
      prepareDailyEmail emails, index+1, data, callback
  else
    callback data

# runnedOnce = no

dailyEmails = ->
  {JMailNotification, JUser} = worker.models

  # if runnedOnce then return
  # runnedOnce = yes

  log "Creating Daily emails..."

  today = new Date()
  today.setDate    today.getDate() - 1
  today.setHours   0
  today.setMinutes 0
  yesterday = today

  JUser.each {"emailFrequency.daily": true}, {}, (err, user)->
    if err then console.error err
    else
      if user
        user.fetchOwnAccount (err, account)->
          if err then console.error err
          else
            notifications = []
            JMailNotification.each {receiver   : account.getId(),  \
                                    dateIssued : $gte: yesterday}, \
                                   {sort       : dateIssued: 1},
            (err, email)->
              if err then console.error err
              else
                if email
                  notifications.push email
                else if notifications.length > 0
                  prepareDailyEmail notifications, 0, (emailContent)->
                    if emailContent.length > 0
                      content = ''
                      for email in emailContent
                        content += template.singleEvent email
                      sendDailyEmail emailContent[0], content

instantEmailsCron = new CronJob emailWorker.cronInstant, instantEmails
log "Instant Emails CronJob started with #{emailWorker.cronInstant}"
instantEmailsCron.start()

dailyEmailsCron = new CronJob emailWorker.cronDaily, dailyEmails
log "Daily Emails CronJob started with #{emailWorker.cronDaily}"
dailyEmailsCron.start()

log "All e-mail notifications will be send to #{emailWorker.forcedRecipient}" if emailWorker.forcedRecipient
