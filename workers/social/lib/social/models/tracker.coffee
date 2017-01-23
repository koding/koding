bongo        = require 'bongo'
KodingError  = require '../error'
KodingLogger = require './kodinglogger'

{ secure, signature } = bongo

_ = require 'lodash'

KONFIG        = require 'koding-config-manager'
{ socialapi } = KONFIG
exchangeName  = "#{socialapi.eventExchangeName}:0"
exchangeOpts  = { autoDelete: no, durable: yes, type: 'fanout', confirm: true }

try
  Analytics = require('analytics-node')
  analytics = new Analytics(KONFIG.segment)
catch e
  console.warn 'Segment disabled because of missing configuration'

module.exports = class Tracker extends bongo.Base

  @share()

  @set
    sharedMethods:
      static:
        track: (signature String, Object, Function)

  { forcedRecipientEmail, forcedRecipientUsername, defaultFromMail } = KONFIG.email

  EVENT_TYPE = 'api.mail_send'

  @types = require './trackingtypes'

  @properties = {}

  @properties[@types.FINISH_REGISTER] = {
    category: 'NewAccount', label: 'VerifyAccount'
  }

  @identifyAndTrack = (username, event, eventProperties = {}, callback = -> ) ->
    @identify username, {}, (err) =>
      return callback err  if err

      @track username, event, eventProperties, callback


  @identify = (username, traits = {}, callback = -> ) ->

    return callback null  unless KONFIG.sendEventsToSegment

    # use `forcedRecipientEmail` for both username and email
    if forcedRecipientEmail
      username     = forcedRecipientUsername
      traits.email = forcedRecipientEmail

    traits = @addDefaults traits
    analytics?.identify { userId: username, traits }

    return  callback null  unless analytics

    # force flush so identify call doesn't sit in queue, while events
    # from Go/other systems are being sent
    analytics.flush (err, batch) ->
      console.error "flushing identify failed: #{err} @sent-hil"  if err
      callback err


  @track$ = secure (client, subject, options = {}, callback) ->

    unless account = client?.connection?.delegate
      err = '[Tracker.track$] Account is not set!'
      console.error err
      return callback new KodingError err

    { profile: { nickname } } = account

    event = { subject }

    { customEvent } = options
    if customEvent
      @handleCustomEvent subject, customEvent, nickname
      delete options.customEvent

    @track nickname, event, options

    callback()

  @track = (username, event, options = {}, callback = -> ) ->

    return callback null  unless KONFIG.sendEventsToSegment

    _.extend options, @properties[event.subject]

    # use `forcedRecipientEmail` for both username and email
    if forcedRecipientEmail
      username = forcedRecipientUsername
      event.to = forcedRecipientEmail

    event.from       or= defaultFromMail
    event.properties   = @addDefaults { options, username }

    require('./socialapi/requests').publishMailEvent event, (err) ->
      callback err # do not cause trailing parameters


  @page = (userId, name, category, properties) ->

    return  unless KONFIG.sendEventsToSegment

    userId = KONFIG.forcedRecipientEmail or userId

    options = { userId, name, category, properties }
    @addDefaults options
    analytics?.page options


  @alias = (previousId, userId) ->

    return  unless KONFIG.sendEventsToSegment

    userId = KONFIG.forcedRecipientEmail or userId

    options = { previousId, userId }
    @addDefaults options
    analytics?.alias options


  @group = (groupId, userId) ->

    return  unless KONFIG.sendEventsToSegment

    userId = KONFIG.forcedRecipientEmail or userId

    options = { groupId, userId }
    @addDefaults options
    analytics?.group options


  @addDefaults = (opts) ->
    opts['env']      = KONFIG.environment
    opts['hostname'] = KONFIG.hostname
    opts


  @handleCustomEvent = (subject, params, nickname) ->

    { STACKS_START_BUILD, STACKS_BUILD_SUCCESSFULLY,
     STACKS_BUILD_FAILED, STACKS_REINIT, STACKS_DELETE } = @types

    return  unless subject in [
      STACKS_START_BUILD, STACKS_BUILD_SUCCESSFULLY
      STACKS_BUILD_FAILED, STACKS_REINIT, STACKS_DELETE
    ]

    { stackId, group } = params
    JGroup = require './group'
    JGroup.one { slug : group }, (err, group) ->
      return console.log err  if err

      { notifyAdmins } = require './notify'
      notifyAdmins group, 'StackStatusChanged',
        id    : stackId
        group : group.slug

      if subject in [ STACKS_BUILD_SUCCESSFULLY, STACKS_BUILD_FAILED ]
        message = "#{nickname}'s #{subject}"
      else
        message = "#{nickname} #{subject}"
      KodingLogger.log group, message
