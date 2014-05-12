class Metric
  @create :(metric, params)->
    {userAgent} = window.navigator

    metric = $.extend { metric, userAgent }, params

    KD.remote.api.JMetric.create metric, ->
