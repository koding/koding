{ argv }      = require 'optimist'
KONFIG        = require('koding-config-manager').load("main.#{argv.c}")
{ DogStatsD } = require 'koding-datadog'

module.exports = Metrics = {

  prefix : 'socialWorker'


  populateTags : (tags) ->

    tags ?= []
    tags.push "version:#{KONFIG.version}"

    return tags


  generateName : (opts) ->

    { method } = opts
    { constructorName, method, type } = method

    return "#{@prefix}.#{constructorName}.#{method}.#{type}"


  send : (opts) ->

    tags                         = Metrics.populateTags()
    metricName                   = Metrics.generateName opts
    dogStatsDClient              = DogStatsD.getClient()
    { rss, heapTotal, heapUsed } = process.memoryUsage()

    dogStatsDClient.gauge "#{metricName}.memory.rss",       rss, tags
    dogStatsDClient.gauge "#{metricName}.memory.heapTotal", heapTotal, tags
    dogStatsDClient.gauge "#{metricName}.memory.heapUsed",  heapUsed, tags

}

