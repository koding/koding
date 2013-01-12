{Base} = require 'bongo'

module.exports = class JSystemStatus extends Base

  @setSharedMethods
    static: ['monitorStatus','scheduleRestart']

  @share()

  {log} = console

  restartData =
    restartScheduled : null
    restartTitle     : null
    restartContent   : null

  # callbacks = []

  @monitorStatus =(callback)->
    log 'monitorStatus called'
    callback restartData  if restartData.restartScheduled?
    # callbacks.push callback

  @scheduleRestart =(data)->
    log 'scheduleRestart called',data
    restartData = data
    # callback restartData  for callback in callbacks
    # @emit 'restartScheduled', data
