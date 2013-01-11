{Base,Model} = require 'bongo'

module.exports = class JSystemStatus extends Model

  @setSharedMethods
    static: ['monitorStatus','scheduleRestart']

  @share()

  restartData =
    restartScheduled : null
    restartTitle     : null
    restartContent   : null

  # callbacks = []

  {log} = console

  @monitorStatus =(callback)->
    log 'monitorStatus called'
    callback restartScheduled  if restartData.restartScheduled?
    # callbacks.push callback

  @scheduleRestart =(data)->
    log 'scheduleRestart called',data
    restartData = data
    # callback restartData  for callback in callbacks
    @emit 'restartScheduled', data