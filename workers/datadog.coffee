os              = require 'os'
KONFIG          = require 'koding-config-manager'
{ MetricsBase } = require 'koding-datadog'

module.exports = class Metrics extends MetricsBase

  @prefix : 'socialWorker'


  @populateCommonTags : (tags) ->

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


  @getMethodMetrics : (opts) ->

    return {
      increment    :
        'count'    : 1
      histogram    :
        'duration' : opts.duration or 0
    }


  @sendMethodMetrics : (opts) ->

    tags       = @populateCommonTags()
    metricName = @generateName opts
    @sendMetrics @getMethodMetrics(opts), metricName, tags
