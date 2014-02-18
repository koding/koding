{Model, Base, secure, daisy, signature} = require 'bongo'
KodingError = require '../error'

module.exports = class JSystemStatus extends Model

  @share()

  @set

    sharedMethods    :
      static         :
        getCurrentSystemStatus:
          (signature Function)
        create:
          (signature Object, Function)
        stopCurrentSystemStatus:
          (signature Function)
        forceReload:
          (do signature)

    sharedEvents     :
      static         : ['forceReload', "restartScheduled"]
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
        enum         : ['Invalid type', ['restart','info','reload']]

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
      return callback no

    JSystemStatus.getCurrentSystemStatus (err,status)=>
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

  @getCurrentSystemStatus = (callback=->)->
    JSystemStatus.one {
      status: 'active'
    }, {
      sort: 'meta.createdAt': -1
    }, (err,status)->
      log err,status if err

      if status and status.scheduledAt > new Date()
        # log 'status: schedule in future, calling back'
        callback err, status
      else
        # log 'schedule in the past. error. error.'
        callback createKodingError('none_scheduled'), null


  @create = secure (client, data, callback=->)->
    {connection:{delegate}} = client
    unless delegate.checkFlag('super-admin')
      log 'status: not authorized to create a system status'
      callback no
    else
      # log 'status: creating new status',data
      {title,content,scheduledAt,type} = data

      JSystemStatus.count {title, content, scheduledAt, type}, \
      (err, count)=>
        if not err and count is 0
          status = new JSystemStatus {
            title
            content
            scheduledAt : new Date(scheduledAt)
            type
            status : 'active'
          }
          # log 'status: created.'
          daisy queue = [
            ->
              JSystemStatus.one {
                status : 'active'
                }, {
                sort:
                  'meta.createdAt' : -1
                }
              ,(err,previousStatus)->
                if err
                  callback err
                else
                  if previousStatus
                    previousStatus.update
                      $set :
                        status : 'stopped'
                    ,(err)->
                      if err
                        callback err
                      else queue.next()
                  else queue.next()
           ->
              status.save (err)->
                if err
                  console.error err
                  callback err
                else
                  # log "status: saved."
                  queue.next()
            =>
              # log 'emitting'
              JSystemStatus.emit 'restartScheduled',status
              callback status
            ]

        else
          log 'status: duplicate found. doing nothing.'