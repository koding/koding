{ Model, Base, secure, signature } = require 'bongo'
KodingError = require '../error'

module.exports = class JSystemStatus extends Model

  Tracker = require './tracker'

  @share()

  @set

    sharedMethods    :
      static         :
        getCurrentSystemStatuses:
          (signature Function)
        create:
          (signature Object, Function)
        stopCurrentSystemStatus:
          (signature Function)
        healthCheck  :
          (signature Function)
        checkRealtimeUpdates:
          (signature Function)
        sendFeedback :
          (signature Object, Function)
      instance       :
        cancel:
          (signature Function)

    sharedEvents     :
      static         : []
      instance       : []

    schema           :
      title          : String
      content        : String
      scheduledAt    : Date
      meta           : require 'bongo/bundles/meta'
      status         :
        type         : String
        default      : 'active'
        enum         : ['Invalid status',
          ['active', 'stopped', 'paused']
        ]
      type           :
        type         : String
        default      : 'restart'
        enum         : ['Invalid type', ['restart', 'info', 'reload', 'red', 'green', 'yellow']]

  createKodingError = (err) ->
    if 'string' is typeof err
      kodingErr = { message: err }
    else
      kodingErr = { message: err.message }
      for own prop of err
        kodingErr[prop] = err[prop]
    kodingErr

  { log } = console

  @stopCurrentSystemStatus = secure (client, callback = -> ) ->
    { connection:{ delegate } } = client
    unless delegate.checkFlag('super-admin')
      log 'status: not authorized to stop a system status'
      return callback new KodingError 'Not authorized to update a system status'

    JSystemStatus.getCurrentSystemStatuses (err, status) ->
      # log err,status
      if err
        # log 'no status to stop'
        callback err, status
      else
        status.update { $set: { status: 'stopped' } }, callback

  @getCurrentSystemStatuses = (callback = -> ) ->
    JSystemStatus.some {
      status: 'active'
      scheduledAt : { $gt : new Date() }
    }, {
      sort: { 'meta.createdAt': -1 }
    }, (err, statuses) ->
      return callback new KodingError 'no queued messages available'  if err

      callback null, statuses


  @create = secure (client, data, callback) ->
    { connection:{ delegate } } = client
    unless delegate.checkFlag('super-admin')
      return callback new KodingError 'Not authorized to create a system status'

    status = new JSystemStatus data
    status.save (err) ->
      callback err, status

  cancel: secure (client, callback) ->
    { connection:{ delegate } } = client
    unless delegate.checkFlag('super-admin')
      return callback new KodingError 'Not authorized to cancel a system status'

    @update { $set : { status : 'stopped' } }, (err) ->
      unless err
        callback()
      else
        callback callback new KodingError 'Could not cancel the system status'

  @healthCheck = secure (client, callback) ->
    callback { result:1 }

  @checkRealtimeUpdates = secure (client, callback) ->
    { connection: { delegate } } = client
    delegate.sendNotification 'healthCheck'
    callback { result:1 }

  @sendFeedback = secure (client, options, callback) ->
    { connection: { delegate } } = client
    { status, feedback, userAgent } = options

    { recipientEmail } = KONFIG.troubleshoot

    delegate.fetchEmail client, (err, email) ->
      return callback err  if err

      Tracker.track delegate.profile.nickname, {
        to      : recipientEmail
        subject : Tracker.types.SENT_FEEDBACK
      }, { status, userAgent, feedback, userEmail:email }

      callback null
