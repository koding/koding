# ~ GG

{argv}    = require 'optimist'
{CronJob} = require 'cron'
Bongo     = require 'bongo'
Broker    = require 'broker'
htmlify   = require 'koding-htmlify'

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
  models : ['../social/lib/social/models/email.coffee']
}

log = ->
  console.log "[E-MAIL SENDER]", arguments...

log "E-Mail Sender Worker has started with PID #{process.pid}"

sendEmail = (emailContent)->
  {from, replyto, email, subject, content, unsubscribeId, force} = emailContent

  cb = ->
    to    = emailWorker.defaultRecepient or email
    from  = if from is 'hello@koding.com' then "Koding <#{from}>" else from
    Emailer.send
      From      : from
      To        : to
      Subject   : subject or "Notification"
      HtmlBody  : template.htmlTemplate htmlify(content, linkStyle:template.linkStyle), unsubscribeId, email
      TextBody  : template.textTemplate content, unsubscribeId, email
      ReplyTo   : replyto
    , (err, status)->
      dateAttempted = new Date()
      status        = 'attempted'
      unless err then log "An e-mail sent to #{to}"
      else
        log "An error occured: #{err}"
        status = 'failed'

      emailContent.update $set: {status, dateAttempted}, (err)->
        console.error err if err

  unless force
    emailContent.isUnsubscribed (err, unsubscribed)->
      if err or unsubscribed
        console.error err  if err
        return emailContent.update $set: {status: 'unsubscribed'}, (err)->
          console.error err  if err
          cb()
      else
        cb()
  else
    cb()

emailSender = ->
  {JMail} = worker.models
  JMail.some {status: "queued"}, {limit:300}, (err, emails)->
    if err
      log "Could not load email queue!"
    else
      if emails.length > 0
        currentIds = [email._id for email in emails][0]
        JMail.update {_id: $in: currentIds}, {$set: status: 'sending'}, \
                     {multi: yes}, (err)->
          unless err
            log "Sending #{emails.length} e-mail(s)..."
            for email in emails
              sendEmail email
          else
            log err

emailSenderCron = new CronJob emailWorker.cronInstant, emailSender
log "Email Sender CronJob started with #{emailWorker.cronInstant}"
emailSenderCron.start()

if emailWorker.defaultRecepient
  log "All e-mails will be send to #{emailWorker.defaultRecepient}"
