kd = require 'kd'
KDObject = kd.Object
remote = require('app/remote').getInstance()

module.exports = class DatadogMetrics extends KDObject

  @buffer = kd.utils.dict()


  @startTimer = (name, state = '') ->

    key = "#{name}:#{state}:Timer"
    @buffer[name] = Date.now()


  @endTimer = (name, state = '') ->

    key = "#{name}:#{state}:Timer"

    return  unless startTime = @buffer[key]

    now = Date.now()

    # difference in milliseconds
    difference = startTime - now

    # duration in seconds
    duration = Math.ceil(difference / 1000)

    DatadogMetrics.collect name, state, duration


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

    unless data.length
      @inProgress = no
      return

    remote.api.DataDog.sendMetrics data, (err) =>
      if err
        console.error 'Metrics:', err
        @inProgress = no
        return

      for key in Object.keys metrics
        @buffer[key] -= metrics[key]

      @inProgress = no


  remote.once 'ready', ->

    do ->

      kd.utils.repeat 5 * 1000, -> DatadogMetrics.send()
