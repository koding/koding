bongo  = require 'bongo'
{argv} = require 'optimist'

KONFIG       = require('koding-config-manager').load("main.#{argv.c}")
{socialapi}  = KONFIG
exchangeName = "#{socialapi.eventExchangeName}:0"
exchangeOpts = {autoDelete: no, durable:yes, type :'fanout'}

Analytics = require('analytics-node')
analytics = new Analytics(KONFIG.segment)

mqClient = null

module.exports = class Tracker

  KodingError = require '../error'

  {forcedRecipient, defaultFromMail} = KONFIG.email

  EVENT_TYPE = 'api.mail_send'

  @types =
    START_REGISTER       : 'started to register'
    FINISH_REGISTER      : 'finished register'
    LOGGED_IN            : 'logged in'
    CONFIRM_USING_TOKEN  : 'confirmed & logged in using token'
    REQUEST_NEW_PASSWORD : 'requested a new password'
    CHANGED_PASSWORD     : 'changed their password'
    REQUEST_EMAIL_CHANGE : 'requested pin to change email'
    CHANGED_EMAIL        : 'changed their email'
    INVITED_GROUP        : 'was invited to a group'
    SENT_FEEDBACK        : 'sent feedback'


  @identifyAndTrack = (username, event, eventProperties = {}) ->
    @identify username
    @track username, event, eventProperties


  @identify = (username, traits={}) ->
    # use `forcedRecipient` for both username and email
    if forcedRecipient
      username     = forcedRecipient
      traits.email = forcedRecipient

    traits = @addDefaults traits
    analytics.identify { userId: username, traits }

    # force flush so identify call doesn't sit in queue, while events
    # from Go/other systems are being sent
    analytics.flush (err, batch)-> console.error err  if err


  @track = (username, mail, options={})->
    # use `forcedRecipient` for both username and email
    if forcedRecipient
      username = forcedRecipient
      mail.to  = forcedRecipient

    mail.from       or= defaultFromMail
    mail.properties   = @addDefaults { options, username }

    unless mqClient
      return console.error 'RabbitMQ client not found for class `Tracker` @sent-hil'

    sendMessage =->
      mqClient.exchange "#{exchangeName}", exchangeOpts, (exchange) =>
        unless exchange
          return console.error "Exchange not found to queue: #{exchangeName} @sent-hil"

        exchange.publish '', mail, type:EVENT_TYPE
        exchange.close()

    if mqClient.readyEmitted then sendMessage()
    else mqClient.on 'ready', -> sendMessage()


  @addDefaults = (opts) ->
    opts['env']      = KONFIG.environment
    opts['hostname'] = KONFIG.hostname

    opts


  @setMqClient = (m)-> mqClient = m
