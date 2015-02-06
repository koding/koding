class DatadogMetrics extends KDObject

  @buffer = KD.utils.dict()


  @collect = (name, state, count = 1) ->

    key = "#{name}:#{state}"
    @buffer[key] ?= 0
    @buffer[key] += count


  @send = ->

    return  if @inProgress

    keys = Object.keys @buffer
    return  unless keys.length

    @inProgress = yes

    metrics = KD.utils.dict()
    data = []

    for key in keys when (count = @buffer[key]) > 0
      metrics[key] = count
      data.push "#{key}:#{count}"

    return  unless data.length

    KD.remote.api.DataDog.sendMetrics data, (err) =>
      return console.error 'Metrics:', err  if err

      for key in Object.keys metrics
        @buffer[key] -= metrics[key]

      @inProgress = no


  do ->

    KD.utils.repeat 5 * 1000, -> DatadogMetrics.send()
