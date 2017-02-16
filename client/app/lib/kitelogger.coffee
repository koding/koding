debug   = (require 'debug') 'kitelogger'

kd      = require 'kd'
globals = require 'globals'

remote  = require('./remote')


module.exports = class KiteLogger

  @buffer = kd.utils.dict()

  @log = (kiteName, rpcCall, state, args, err) ->

    # Comment-out following lines if you need extensive logging
    # for all the kite calls from client side ~ GG
    #
    key = "#{kiteName}.#{rpcCall}"
    debug "#{state}", key, args
    debug "#{state} failed", err  if err

    key = "#{kiteName}.#{rpcCall}:#{state}"

    @buffer[key] ?= 0
    @buffer[key]++

  ['failed', 'success', 'queued', 'started'].forEach (helper) =>
    @[helper] = (kiteName, rpcCall, args, err) ->
      @log kiteName, rpcCall, helper, args, err

  @consume = ->

    return  if (Object.keys KiteLogger.buffer).length is 0
    return  if @consumeInProgress
    @consumeInProgress = yes

    data = []
    for own key, count of KiteLogger.buffer
      data.push "#{key}:#{count}"  if count > 0
      KiteLogger.buffer[key] = 0

    if data.length is 0
      @consumeInProgress = no
      return

    remote.api.DataDog.sendMetrics data, (err) =>
      kd.warn '[KiteLogger] failed:', err  if err?
      @consumeInProgress = no


  if globals.config.environment is 'production'
    @interval = 10000 # 10 seconds
    @timer = kd.utils.repeat @interval, @consume
