# ~ GG
process.title = 'koding-emailsender'
{argv}        = require 'optimist'
{CronJob}     = require 'cron'
Bongo         = require 'bongo'
Broker        = require 'broker'
htmlify       = require 'koding-htmlify'
Emailer       = require '../social/lib/social/emailer'
template      = require './templates'

{mq, mongo, emailWorker, uri} = \
  require('koding-config-manager').load("main.#{argv.c}")

if 'string' is typeof mongo
  mongo = "mongodb://#{mongo}?auto_reconnect"

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
  {from, replyto, email, subject, content, unsubscribeId, bcc} = emailContent

  To       = emailWorker.forcedRecipient or email
  From     = if from is 'hello@koding.com' then "Koding <#{from}>" else from
  HtmlBody = template.htmlTemplate htmlify(content, linkStyle:template.linkStyle), unsubscribeId, email
  TextBody = template.textTemplate content, unsubscribeId, email

  Emailer.send {
    From
    To
    Subject   : subject or "Notification"
    HtmlBody
    TextBody
    ReplyTo   : replyto
    Bcc       : bcc
  }, (err, res)->

    dateAttempted = new Date()

    if err
      console.warn "An error occured: #{err}"
      status = 'failed'
      smtpId = null
    else
      { smtpId } = res?.messageId
      log "An e-mail sent to #{To}"
      status = 'attempted'

    emailContent.update $set: {status, dateAttempted, smtpId}, (err)->
      console.error err if err

emailSender = ->
  {JMail} = worker.models

  today = new Date()
  today.setDate    today.getDate() - emailWorker.maxAge
  today.setHours   0
  today.setMinutes 0
  daysAgo = today

  query = {
    status     : "queued"
    dateIssued : $gte: daysAgo
  }

  JMail.fetchWithUnsubscribedInfo query, {limit:300}, (err, emails)->

    if err
      log "Could not load email queue!"
    else
      if emails.length > 0
        currentIds = [email._id for email in emails][0]
        JMail.update {_id: $in: currentIds}, {$set: status: 'sending'}, \
                     {multi: yes}, (err)->
          unless err
            log "Sending #{emails.length} e-mail(s)..."

            sendEmail email  for email in emails
          else
            log err

emailSenderCron = new CronJob emailWorker.cronInstant, emailSender
log "Email Sender CronJob started with #{emailWorker.cronInstant}"
emailSenderCron.start()

if emailWorker.forcedRecipient
  log "All e-mails will be send to #{emailWorker.forcedRecipient}"
