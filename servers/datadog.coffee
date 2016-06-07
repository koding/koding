{ argv }        = require 'optimist'
KONFIG          = require 'koding-config-manager'
onFinished      = require 'on-finished'
{ MetricsBase } = require 'koding-datadog'

module.exports = class MetricsMiddleware extends MetricsBase

  @prefix : 'nodejs.webserver'


  @sanitizeMetricName : (string) ->

    return string
      .replace /\/$/g,                 ''   # removing last /
      .replace /[\/-]/g,               '.'  # replace all / with .
      .replace /\.{2,}/g,              '.'  # remove adjacent dots
      .replace /[^a-zA-Z0-9_\.]/g,     '_'  # replace invalid characters with _


  @generateName : (req) ->

    path = switch
      when req?.route?.path is '*'  then req.path
      when req?.route?              then req.route.path
      else                               req.path

    path = 'home'  if path is '/'
    @sanitizeMetricName "#{@prefix}.#{path}"


  @populateTags : (req, res, tags) ->

    tags ?= []
    tags.push "version:#{KONFIG.version}"
    tags.push "http_method:#{req.method}"
    tags.push "http_response_code:#{res.statusCode}"

    return tags


  @metricsOnFinished : (opts) ->

    return {
      increment         :
        'page_view'     : 1
      histogram         :
        'response_time' : opts.elapsedTime or 0
    }


  @send : (req, res, next) =>

    start = new Date()

    onFinished res, =>
      metricName  = @generateName req
      tags        = @populateTags req, res
      elapsedTime = new Date() - start
      @sendMetrics @metricsOnFinished({ elapsedTime }), metricName, tags

    next()
