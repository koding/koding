{Base,secure} = require 'bongo'

module.exports = class JSystemStatus extends Base

  @set
    sharedMethods :
      static: ['monitorStatus','scheduleRestart','cancelRestart']

  @share()

  restartData =
    restartScheduled : null
    restartTitle     : null
    restartContent   : null

  @monitorStatus =(callback)->
    callback restartData  if restartData.restartScheduled?

  @scheduleRestart = secure (client, data, callback)->
    {connection:{delegate}} = client
    if delegate.checkFlag('super-admin')
      restartData = data
      @emit 'restartScheduled', data
      callback? yes
    else
      callback? no

  @cancelRestart = secure (client, callback)->
    {connection:{delegate}} = client
    if delegate.checkFlag('super-admin')
      @emit 'restartScheduled',
        canceled : yes
      restartData =
        restartScheduled : null
        restartTitle     : null
        restartContent   : null
      callback? yes
    else
      callback? no

