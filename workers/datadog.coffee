os              = require 'os'
{ argv }        = require 'optimist'
KONFIG          = require('koding-config-manager').load("main.#{argv.c}")
monitor         = require('appmetrics').monitor()
{ DogStatsD
  MetricsBase } = require 'koding-datadog'

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


  @populateNodejsTags : (tags) ->

    tags ?= []

    tagList = {
      os      : [ 'type', 'release', 'hostname' ]
      process : [ 'cwd', 'pid', 'argv', 'title', 'getuid', 'getgid',
        'version', 'platform', 'execPath' ]
    }

    for key, value of tagList
      for prop in value
        tagName  = "#{key}.#{prop}"
        tagValue = ''

        source = switch
          when key is 'process'  then process
          when key is 'os'       then os

        tagValue = switch
          when not source[prop]                   then 0
          when Array.isArray source[prop]         then source[prop].join()
          when typeof source[prop] is 'function'  then source[prop]()
          else                                         source[prop]

        tagValue = @sanitizeTagValue tagValue
        tags.push "#{tagName}:#{tagValue}"

    return tags


  @startMonitoringNodejs : ->

    tags = @populateCommonTags()
    tags = @populateNodejsTags(tags)

    monitor.on 'eventloop', (eventloop) =>
      eventloopMetrics =
        gauge           :
          'latency.min' : eventloop.latency.min
          'latency.max' : eventloop.latency.max
          'latency.avg' : eventloop.latency.avg

      @sendMetrics eventloopMetrics, 'nodejs.eventloop', tags

    monitor.on 'memory', (memory) =>
      memMetrics =
        gauge                :
          'process.private'  : memory.private
          'process.physical' : memory.physical
          'process.virtual'  : memory.virtual
          'system.used'      : memory.physical_used
          'system.total'     : memory.physical_total

      @sendMetrics memMetrics, 'nodejs.memory', tags

    monitor.on 'gc', (gc) =>
      gcMetrics =
        gauge      :
          size     : gc.size
          used     : gc.used
          duration : gc.duration

      @sendMetrics gcMetrics, 'nodejs.gc', tags

    monitor.on 'cpu', (cpu) =>
      cpuMetrics =
        gauge     :
          process : cpu.process
          system  : cpu.system

      @sendMetrics cpuMetrics, 'nodejs.cpu', tags


