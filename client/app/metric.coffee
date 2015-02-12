class Metric
  @create : KD.utils.throttle 500, (metric, params={})->
    return  unless KD.config.logToInternal

    {userAgent} = window.navigator

    metric = $.extend { metric, userAgent }, params

    KD.remoteLog.api.JMetric.create metric, ->
