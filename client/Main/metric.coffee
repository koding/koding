class Metric
  @create : KD.utils.throttle 500, (metric, params={})->
    {userAgent} = window.navigator

    metric = $.extend { metric, userAgent }, params

    KD.remote.api.JMetric.create metric, ->
