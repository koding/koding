{ argv }        = require 'optimist'
KONFIG          = require('koding-config-manager').load("main.#{argv.c}")
{ MetricsBase } = require 'koding-datadog'

module.exports = class Metrics extends MetricsBase

  @prefix : 'socialWorker'


  @populateTags : (tags) ->

    tags ?= []
    tags.push "version:#{KONFIG.version}"

    return tags


  @generateName : (opts) ->

    notDefined      = 'undefined'
    method          = opts.method            ? {}

    type            = method.type            ? notDefined
    methodName      = method.method          ? notDefined
    constructorName = method.constructorName ? notDefined

    return "#{@prefix}.#{constructorName}.#{methodName}.#{type}"


  @methodMetrics : (opts) ->

    return {
      increment    :
        'count'    : 1
      histogram    :
        'duration' : opts.duration or 0
    }


  @sendMethodMetrics : (opts) ->

    tags       = @populateTags()
    metricName = @generateName opts
    @sendMetrics @methodMetrics(opts), metricName, tags



