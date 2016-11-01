{ Module } = require 'jraphical'
KONFIG     = require 'koding-config-manager'

module.exports = class JLog extends Module

  TRY_LIMIT_FOR_BLOCKING = 5
  TIME_LIMIT_IN_MIN      = if KONFIG.environment is 'sandbox' then 1 else 5

  @set
    softDelete      : no
    indexes         :
      username      : 1
      ip            : 1
    sharedEvents    :
      static        : []
      instance      : []
    schema          :
      type          :
        type        : String
        required    : yes
        set         : (value) -> value.toLowerCase()
      ip            :
        type        : String
        required    : yes
        default     : '127.0.0.1'
      username      :
        type        : String
        required    : yes
        default     : 'guest'
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


  @log = (data, callback = -> ) ->

    log = new JLog data
    log.save (err) -> callback err


  @timeLimit = -> TIME_LIMIT_IN_MIN


  @tryLimit = -> TRY_LIMIT_FOR_BLOCKING


  checkRestrictions = (err, results, callback) ->

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
    headUntil = (list, condition) ->
      head = []
      for i in list
        return head if condition(i)
        head.push i
      return head

    results = headUntil results, (el) -> el.success is true
    # we dont need anything older than 5 minutes
    results = headUntil results, (el) -> ((Date.now() - el.createdAt) / 1000 / 60) > TIME_LIMIT_IN_MIN
    # if items length is lt CHECK_LIMIT return true
    callback results.length < TRY_LIMIT_FOR_BLOCKING


  @checkLoginBruteForce = (data, callback) ->

    { ip, username } = data

    return callback true  unless username

    options =
      limit       : TRY_LIMIT_FOR_BLOCKING
      sort        :
        createdAt : -1

    JLog.some { username }, options, (err, results) ->
      checkRestrictions err, results, (res) ->
        return callback false  unless res
        return callback true
