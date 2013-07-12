{Module} = require 'jraphical'

module.exports = class JLog extends Module

  {secure, daisy} = Bongo = require 'bongo'

  @share()


  TRY_LIMIT_FOR_BLOCKING = 5
  @TIME_LIMIT_IN_MIN = 5
  TIME_LIMIT_IN_MS = @TIME_LIMIT_IN_MIN * 60000 #TIME_LIMIT_IN_MIN * 60sec * 1000ms

  @set
    softDelete      : yes
    sharedMethods   :
      instance      : []
      static        : [ 'some', 'log', 'checkLoginBruteForce' ]
    schema                :
      type                :
        type              : String
        required          : yes
        set               : (value)-> value.toLowerCase()
      ip                  :
        type              : String
        required          : yes
        default           : "127.0.0.1"
      username            :
        type              : String
        required          : yes
        default           : "guest"
      createdAt           :
        type              : Date
        default           : -> new Date
      success             :
        type              : Boolean
        default           : true
      severity            :
        type              : Number
        default           : 5
      payload             :
        type              : String
        required          : no

  @log = (data, callback)->
    log = new JLog data
    log.save (err) -> callback err

  checkRestrictions = (err, results, callback)->
    # if err dont let to login
    if err then return callback false

    # if items length is lt CHECK_LIMIT return true
    if results.length < TRY_LIMIT_FOR_BLOCKING
      return callback true

    # if first results' createdAt lt 5 min return false
    resultTimestamp = results[TRY_LIMIT_FOR_BLOCKING-1].createdAt.getTime()+TIME_LIMIT_IN_MS
    currentTimestamp = Date.now()

    if resultTimestamp > currentTimestamp
      return callback false

    return callback true

  @checkLoginBruteForce = (data, callback)->
    {ip, username} = data

    daisy queue = [
      ->
        queue.next() unless ip
        JLog.some {ip : ip, success: false}, {limit : TRY_LIMIT_FOR_BLOCKING}, (err, results)->
          checkRestrictions err, results, (res)->
            unless res then return callback res
            queue.next()
      ->
        queue.next() unless username
        JLog.some {username : username, success: false}, {limit : TRY_LIMIT_FOR_BLOCKING}, (err, results)->
          checkRestrictions err, results, (res)->
            unless res then return callback res
            queue.next()
      ->
        return callback true
    ]


  @checkBruteForce =(type, data, promise)->
    promise ?= {}
    promise.success ?= (client, callback)-> callback null, yes
    checkBruteForce = secure (client, rest...)->
      if 'function' is typeof rest[rest.length-1]
        [rest..., callback] = rest
      else
        callback =->
      success =
        if 'function' is typeof promise then promise.bind this
        else promise.success.bind this
      failure = promise.failure?.bind this
      JLog.checkLoginBruteForce data, (hasPermission)->
        args = [client, rest..., callback]
        if hasPermission
          success.apply null, args
        else if failure?
          failure.apply null, args
        else
          callback new KodingError 'Access denied'
