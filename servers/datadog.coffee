{ argv }             = require 'optimist'
KONFIG               = require('koding-config-manager').load("main.#{argv.c}")
onHeaders            = require 'on-headers'
{ DogStatsD, Timer } = require 'koding-datadog'


module.exports = MetricsMiddleware = {

  prefix : 'nodejs.webserver'


  sanitize : (string) ->

    return string
      .replace /\/$/g,      'home'  # replace last / with home
      .replace /[\/-]/g,    '.'     # replace all / with .
      .replace /\.{2,}/g,   '.'     # remove adjacent dots

  generateName : (path) -> @sanitize "#{@prefix}.#{path}"


  populateTags : (req, res, tags) ->

    tags ?= []

    tags.push "version:#{KONFIG.version}"
    tags.push "http_method:#{req.method}"
    tags.push "http_response_code:#{res.statusCode}"

    return tags


  send : (req, res, next) ->

    Timer.start()
    metricName      = MetricsMiddleware.generateName(req.path)
    elapsedTime     = 0
    dogStatsDClient = DogStatsD.getClient()

    onHeaders res, ->
      tags        = MetricsMiddleware.populateTags req, res
      elapsedTime = Timer.getElapsedTimeInMilliSecs()
      dogStatsDClient.histogram "#{metricName}.response_time", elapsedTime, tags

    # storing res.end
    end = res.end

    res.end = ->
      console.log req.path
      tags = MetricsMiddleware.populateTags req, res
      dogStatsDClient.increment "#{metricName}.page_view", 1, tags

      # calling end function in res context
      end.apply(res, arguments)

    next()

}
