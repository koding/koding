DatadogMetrics = require 'app/datadogmetrics'
kd = require 'kd'


module.exports = class OnboardingMetrics extends DatadogMetrics

  @collect = (groupName, itemName, count) ->

    name  = "Onboarding"
    state = "#{groupName}:#{itemName}"

    super name, state, count
    kd.log "OnboardingMetrics:   #{name}:#{state}", count ? ""


  @trackCompleted = (groupName, itemName, count = 1) ->

    @collect groupName, "#{itemName}:completed_in", count


  @trackCancelled = (groupName, itemName) ->

    @collect groupName, "#{itemName}:cancelled"