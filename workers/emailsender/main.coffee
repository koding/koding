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
  {from, replyto, email, subject, content, unsubscribeId, bcc} = emailContent

  To       = emailWorker.defaultRecepient or email
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
  }, (err, status)->
    dateAttempted = new Date()
    status        = 'attempted'
    unless err then log "An e-mail sent to #{To}"
    else
      log "An error occured: #{err}"
      status = 'failed'

    emailContent.update $set: {status, dateAttempted}, (err)->
      console.error err if err

emailSender = ->
  {JMail} = worker.models
  JMail.fetchWithUnsubscribedInfo {status: "queued"}, {limit:300}, (err, emails)->
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

if emailWorker.defaultRecepient
  log "All e-mails will be send to #{emailWorker.defaultRecepient}"
