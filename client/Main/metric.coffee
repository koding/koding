class Metric
  @create : KD.utils.throttle 500, (metric, params={})->
    {userAgent} = window.navigator

    metric = $.extend { metric, userAgent }, params

    KD.remote_log.api.JMetric.create metric, ->
