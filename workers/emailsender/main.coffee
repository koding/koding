# ~ GG

{argv}    = require 'optimist'
{CronJob} = require 'cron'
Bongo     = require 'bongo'
Broker    = require 'broker'

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

# Taken and modified from http://stackoverflow.com/a/7138764/1370271
htmlify = (content)->
  # http://, https://, ftp://
  urlPattern = /\b(?:https?|ftp):\/\/[a-z0-9-+&@#\/%?=~_|!:,.;]*[a-z0-9-+&@#\/%=~_|]/gim
  # www. sans http:// or https://
  pseudoUrlPattern = /(^|[^\/])(www\.[\S]+(\b|$))/gim
  # Email addresses *** here I've changed the expression ***
  emailAddressPattern = /(([a-zA-Z0-9_\-\.]+)@[a-zA-Z_]+?(?:\.[a-zA-Z]{2,6}))+/gim

  html   = ""
  chunks = content.split "\n"
  for chunk in chunks when chunk isnt ''
    if chunk.indexOf("- ", 0) is 0
      html += "<li>#{chunk.split('- ')[1]}</li>"
    else
      html += "<p>#{chunk}</p>"

  html
      .replace urlPattern, "<a #{template.linkStyle} target='_blank' href='$&'>$&</a>"
      .replace pseudoUrlPattern, "$1<a #{template.linkStyle} target='_blank' href='http://$2'>$2</a>"
      .replace emailAddressPattern, "<a #{template.linkStyle} target='_blank' href='mailto:$1'>$1</a>"

sendEmail = (emailContent)->
  {from, replyto, email, subject, content} = emailContent
  email     = emailWorker.defaultRecepient or email
  Emailer.send
    From      : from
    To        : email
    Subject   : subject or "[Koding] Notification"
    HtmlBody  : template.htmlTemplate htmlify content
    TextBody  : template.textTemplate content
    ReplyTo   : replyto
  , (err, status)->
    dateAttempted = new Date()
    status        = 'attempted'
    unless err then log "An e-mail sent to #{email}"
    else
      log "An error occured: #{err}"
      status = 'failed'

    emailContent.update $set: {status, dateAttempted}, (err)->
      console.error err if err

emailSender = ->
  {JMail} = worker.models
  JMail.some {status: "queued"}, {limit:300}, (err, emails)->
    if err
      log "Could not load email queue!"
    else
      if emails.length > 0
        log "Sending #{emails.length} e-mail(s)..."
        for email in emails
          sendEmail email

emailSenderCron = new CronJob emailWorker.cronInstant, emailSender
log "Email Sender CronJob started with #{emailWorker.cronInstant}"
emailSenderCron.start()

if emailWorker.defaultRecepient
  log "All e-mails will be send to #{emailWorker.defaultRecepient}"
