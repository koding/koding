{Model, Base, secure, daisy, signature} = require 'bongo'
KodingError = require '../error'

module.exports = class JSystemStatus extends Model

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
        forceReload:
          (do signature)
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
      static         : ['forceReload', 'restartScheduled']
      instance       : ['restartCanceled']

    schema           :
      title          : String
      content        : String
      scheduledAt    : Date
      meta           : require 'bongo/bundles/meta'
      status         :
        type         : String
        default      : 'active'
        enum         : ['Invalid status',
          ['active','stopped','paused']
        ]
      type           :
        type         : String
        default      : 'restart'
        enum         : ['Invalid type', ['restart','info','reload','red','green','yellow']]

  createKodingError =(err)->
    if 'string' is typeof err
      kodingErr = message: err
    else
      kodingErr = message: err.message
      for own prop of err
        kodingErr[prop] = err[prop]
    kodingErr

  {log} = console

  @forceReload = secure (client)->
    {connection:{delegate}} = client
    unless delegate.checkFlag('super-admin')
      log 'status: not authorized to stop a system status'
      return
    @emit 'forceReload'

  @stopCurrentSystemStatus = secure (client, callback=->)->
    {connection:{delegate}} = client
    unless delegate.checkFlag('super-admin')
      log 'status: not authorized to stop a system status'
      return callback new KodingError "Not authorized to update a system status"

    JSystemStatus.getCurrentSystemStatuses (err,status)=>
      # log err,status
      if err
        # log 'no status to stop'
        callback err,status
      else
        status.update {
          $set: status: 'stopped'
        },(err)=>
          status.emit 'restartCanceled', {}
          callback err

  @getCurrentSystemStatuses = (callback=->)->
    JSystemStatus.some {
      status: 'active'
      scheduledAt : $gt : new Date()
    }, {
      sort: 'meta.createdAt': -1
    }, (err,statuses)->
      return callback new KodingError 'no queued messages available'  if err

      callback null, statuses


  @create = secure (client, data, callback)->
    {connection:{delegate}} = client
    unless delegate.checkFlag('super-admin')
      return callback new KodingError "Not authorized to create a system status"

    status = new JSystemStatus data
    status.save (err)->
      JSystemStatus.emit 'restartScheduled',status  unless err
      callback err, status

  cancel: secure (client, callback) ->
    {connection:{delegate}} = client
    unless delegate.checkFlag('super-admin')
      return callback new KodingError "Not authorized to cancel a system status"

    @update $set : status : 'stopped', (err)=>
      unless err
        @emit 'restartCanceled'
        callback()
      else
        callback callback new KodingError "Could not cancel the system status"

  @healthCheck = secure (client, callback) ->
    callback result:1

  @checkRealtimeUpdates = secure (client, callback) ->
    {connection: {delegate}} = client
    delegate.sendNotification "healthCheck"

  @sendFeedback = secure (client, options, callback) ->
    {connection: {delegate}} = client
    {status, feedback, userAgent} = options

    JMail = require './email'
    {recipientEmail} = KONFIG.troubleshoot
    delegate.fetchEmail client, (err, email) ->
      return callback err  if err
      mail = new JMail
        from    : email
        replyto : email
        email   : recipientEmail
        content : "Failed Services: #{status} \n\n User-Agent: #{userAgent} \n\n Feedback: #{feedback}"
        subject : "Feedback from user: #{delegate.profile.nickname}"

      mail.save callback
