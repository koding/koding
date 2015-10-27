bongo    = require 'bongo'

{ secure, signature } = bongo

{ argv } = require 'optimist'

_ = require 'lodash'

KONFIG        = require('koding-config-manager').load("main.#{argv.c}")
{ socialapi } = KONFIG
exchangeName  = "#{socialapi.eventExchangeName}:0"
exchangeOpts  = { autoDelete: no, durable:yes, type :'fanout' }

Analytics = require('analytics-node')
analytics = new Analytics(KONFIG.segment)

mqClient = null

module.exports = class Tracker extends bongo.Base

  @share()

  @set
    sharedMethods:
      static:
        track: (signature String, Object, Function)

  { forcedRecipient, defaultFromMail } = KONFIG.email

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
    INVITED_CREATE_TEAM  : 'was invited to create a team'
    SENT_FEEDBACK        : 'sent feedback'

  @properties = {}

  @properties[@types.FINISH_REGISTER] = {
    category: 'NewAccount', label: 'VerifyAccount'
  }

  @identifyAndTrack = (username, event, eventProperties = {}) ->
    @identify username
    @track username, event, eventProperties


  @identify = (username, traits = {}) ->
    return  unless KONFIG.sendEventsToSegment

    # use `forcedRecipient` for both username and email
    if forcedRecipient
      username     = forcedRecipient
      traits.email = forcedRecipient

    traits = @addDefaults traits
    analytics.identify { userId: username, traits }

    # force flush so identify call doesn't sit in queue, while events
    # from Go/other systems are being sent
    analytics.flush (err, batch) ->
      console.error "flushing identify failed: #{err} @sent-hil"  if err


  @track$ = secure (client, subject, options = {}, callback) ->

    { profile: { nickname } } = client.connection.delegate

    event = { subject }

    @track nickname, event, options

    callback()


  @track = (username, event, options = {}) ->
    return  unless KONFIG.sendEventsToSegment

    _.extend options, @properties[event.subject]

    # use `forcedRecipient` for both username and email
    if forcedRecipient
      username = forcedRecipient
      event.to  = forcedRecipient

    event.from       or= defaultFromMail
    event.properties   = @addDefaults { options, username }

    unless mqClient
      return console.error 'Tracker: RabbitMQ client not set'

    sendMessage = ->
      mqClient.exchange "#{exchangeName}", exchangeOpts, (exchange) ->
        unless exchange
          return console.error "Tracker: Exchange not found to queue: #{exchangeName}"

        exchange.publish '', event, { type: EVENT_TYPE }
        exchange.close()

    if mqClient.readyEmitted then sendMessage()
    else mqClient.on 'ready', -> sendMessage()


  @page = (userId, name, category, properties) ->

    return  unless KONFIG.sendEventsToSegment

    userId = KONFIG.forcedRecipient or userId

    options = { userId, name, category, properties }
    @addDefaults options
    analytics.page options


  @alias = (previousId, userId) ->

    return  unless KONFIG.sendEventsToSegment

    userId = KONFIG.forcedRecipient or userId

    options = { previousId, userId }
    @addDefaults options
    analytics.alias options


  @addDefaults = (opts) ->
    opts['env']      = KONFIG.environment
    opts['hostname'] = KONFIG.hostname
    opts


  @setMqClient = (m) -> mqClient = m
