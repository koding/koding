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

  VERSION_1  = ' v1'
  EVENT_TYPE = 'api.mail_send'

  @types =
    WELCOME          : 'welcome'          + VERSION_1
    INVITE           : 'invite'           + VERSION_1
    FEEDBACK         : 'feedback'         + VERSION_1
    EMAIL_CHANGED    : 'email changed'    + VERSION_1
    PASSWORD_CHANGED : 'password changed' + VERSION_1
    CONFIRM_EMAIL    : 'confirm email'    + VERSION_1
    PASSWORD_RECOVER : 'password recover' + VERSION_1

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
