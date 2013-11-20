{Module} = require 'jraphical'

module.exports = class JLog extends Module

  {secure, daisy} = Bongo = require 'bongo'

  # no need to share for now
  # @share()


  TRY_LIMIT_FOR_BLOCKING = 5
  TIME_LIMIT_IN_MIN = 5

  @set
    softDelete      : yes
    sharedMethods   :
      instance      : []
      static        : []
    sharedEvents    :
      static        : []
      instance      : []
    indexes         :
      username      : 1
      ip            : 1
    schema          :
      type          :
        type        : String
        required    : yes
        set         : (value)-> value.toLowerCase()
      ip            :
        type        : String
        required    : yes
        default     : "127.0.0.1"
      username      :
        type        : String
        required    : yes
        default     : "guest"
      createdAt     :
        type        : Date
        default     : -> new Date
      success       :
        type        : Boolean
        default     : true
      severity      :
        type        : Number
        default     : 5
      payload       :
        type        : String
        required    : no

  @log = (data, callback)->
    log = new JLog data
    log.save (err) -> callback err

  @timeLimit = ()->
    TIME_LIMIT_IN_MIN

  checkRestrictions = (err, results, callback)->
    # if err dont let to login
    if err then return callback false

    # we get last 5 lines from log like this
    # - 1, false
    # - 2, false
    # - 3, true
    # - 4, false
    # - 5, false
    # if whe have a successful login attempt in them,
    # we count from there, trimming list to
    # - 1 - false
    # - 2 - false
    headUntil = (list, condition)->
      head = []
      for i in list
        return head if condition(i)
        head.push i
      return head

    results = headUntil results, (el)-> el.success is true
    # we dont need anything older than 5 minutes
    results = headUntil results, (el)-> ((Date.now() - el.createdAt) / 1000 / 60) > TIME_LIMIT_IN_MIN
    # if items length is lt CHECK_LIMIT return true
    callback results.length < TRY_LIMIT_FOR_BLOCKING

  @checkLoginBruteForce = (data, callback)->
    {ip, username} = data

    daisy queue = [
      ->
        return queue.next() unless ip
        # do we have 5 failed login attempts from this ip...
        JLog.some {ip : ip}, {limit : TRY_LIMIT_FOR_BLOCKING, sort: createdAt: -1}, (err, results)->
          checkRestrictions err, results, (res)->
            unless res then return callback res
            queue.next()
      ->
        return queue.next() unless username
        JLog.some {username : username}, {limit : TRY_LIMIT_FOR_BLOCKING, sort: createdAt: -1}, (err, results)->
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
