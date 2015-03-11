globals = require 'globals'
kd = require 'kd'
remote = require('./remote').getInstance()
module.exports = class KiteLogger

  @buffer = kd.utils.dict()

  @log = (kiteName, rpcCall, state) ->

    key = "#{kiteName}.#{rpcCall}:#{state}"
    # log "[KITELOGGER]", key

    @buffer[key] ?= 0
    @buffer[key]++

  ['failed', 'success', 'queued', 'started'].forEach (helper)=>
    @[helper] = (kiteName, rpcCall) ->
      @log kiteName, rpcCall, helper

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
      kd.warn "[KiteLogger] failed:", err  if err?
      @consumeInProgress = no


  if globals.config.environment is 'production'
    @interval = 10000 # 10 seconds
    @timer = kd.utils.repeat @interval, @consume



