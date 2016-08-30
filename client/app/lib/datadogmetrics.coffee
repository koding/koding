kd = require 'kd'
KDObject = kd.Object
remote = require 'app/remote'

module.exports = class DatadogMetrics extends KDObject

  @buffer = kd.utils.dict()


  @collect = (name, state, count = 1) ->

    key = "#{name}:#{state}"
    @buffer[key] ?= 0
    @buffer[key] += count


  @send = ->

    return  if @inProgress

    keys = Object.keys @buffer
    return  unless keys.length

    @inProgress = yes

    metrics = kd.utils.dict()
    data = []

    for key in keys when (count = @buffer[key]) > 0
      metrics[key] = count
      data.push "#{key}:#{count}"

    return  unless data.length

    remote.api.DataDog.sendMetrics data, (err) =>
      return console.error 'Metrics:', err  if err

      for key in Object.keys metrics
        @buffer[key] -= metrics[key]

      @inProgress = no


  interval = null

  startInterval = ->

    return  if interval
    interval = kd.utils.repeat 5 * 1000, -> DatadogMetrics.send()

  stopInterval = ->

    kd.utils.killRepeat interval
    interval = null


  remote.on 'connected', ->

    return  if interval

    { mainController } = kd.singletons
    mainController.on 'AccountChanged', (account) ->

      if account.type is 'registered'
      then startInterval()
      else stopInterval()


  remote.on 'disconnected', stopInterval
