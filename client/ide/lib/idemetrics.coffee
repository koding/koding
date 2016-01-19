DatadogMetrics = require 'app/datadogmetrics'

module.exports = class IDEMetrics extends DatadogMetrics

  @collect = (name, state, count = 1) ->

    name = "IDE.#{name}"

    super name, state, count
