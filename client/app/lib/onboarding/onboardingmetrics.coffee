DatadogMetrics = require 'app/datadogmetrics'
kd = require 'kd'


module.exports = class OnboardingMetrics extends DatadogMetrics

  @collect = (groupName, itemName, count) ->

    name  = 'Onboarding'
    state = "#{groupName}:#{itemName}"

    super name, state, count


  @trackCompleted = (groupName, itemName, count) ->

    @collect groupName, "#{itemName}:completed_in", count


  @trackCancelled = (groupName, itemName) ->

    @collect groupName, "#{itemName}:cancelled"