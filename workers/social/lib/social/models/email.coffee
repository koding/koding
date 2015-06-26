bongo  = require 'bongo'
{argv} = require 'optimist'

KONFIG       = require('koding-config-manager').load("main.#{argv.c}")
{socialapi}  = KONFIG
exchangeName = "#{socialapi.eventExchangeName}:0"
exchangeOpts = {autoDelete: no, durable:yes, type :'fanout'}

mqClient = null

module.exports = class Email

  KodingError = require '../error'

  {forcedRecipient, defaultFromMail} = KONFIG.email

  EVENT_TYPE = 'api.mail_send'

  @types =
    START_REGISTER       : 'started to register'
    INVITED_GROUP        : 'was invited to a group'
    SENT_FEEDBACK        : 'sent feedback'
    REQUEST_NEW_PASSWORD : 'requested a new password'
    CHANGED_PASSWORD     : 'changed their password'
    REQUEST_EMAIL_CHANGE : 'requested pin to change email'
    CHANGED_EMAIL        : 'changed their email'

  @setMqClient = (m)-> mqClient = m

  @queue = (username, mail, options, callback)->
    mail.to           = forcedRecipient or mail.to
    mail.from       or= defaultFromMail
    mail.properties   = { options, username}

    unless mqClient
      return callback new KodingError 'RabbitMQ client not found in Email'

    sendMessage =->
      mqClient.exchange "#{exchangeName}", exchangeOpts, (exchange) =>
        unless exchange
          return console.error "Exchange not found to queue Email!: #{exchangeName} @sent-hil"

        exchange.publish "", mail, type:EVENT_TYPE
        exchange.close()

    if mqClient.readyEmitted then sendMessage()
    else mqClient.on "ready", -> sendMessage()

    callback null
