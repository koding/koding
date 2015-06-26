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
    WELCOME          : 'started to register'
    CONFIRM_EMAIL    : 'started to register'
    UPDATED_EMAIL    : 'updated email'
    INVITE           : 'was invited to a group'
    FEEDBACK         : 'sent feedback'
    EMAIL_CHANGED    : 'email was changed'
    PASSWORD_CHANGED : 'password was changed'
    PASSWORD_RECOVER : 'requested a new password'

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
