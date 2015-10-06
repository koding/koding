{ argv }        = require 'optimist'
KONFIG          = require('koding-config-manager').load("main.#{argv.c}")
os              = require 'os'
{ MetricsBase } = require 'koding-datadog'

module.exports = class Metrics extends MetricsBase

  @prefix : 'socialWorker'


  @populateTags : (tags) ->

    tags ?= []
    tags  = @populateCommonTags tags
    tags.push "version:#{KONFIG.version}"

    return tags


  @generateName : (opts) ->

    { method } = opts
    { constructorName, method, type } = method

    return "#{@prefix}.#{constructorName}.#{method}.#{type}"


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



