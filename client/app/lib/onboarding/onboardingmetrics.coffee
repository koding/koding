DatadogMetrics = require 'app/datadogmetrics'
kd = require 'kd'


module.exports = class OnboardingMetrics extends DatadogMetrics

  ###*
   * Overrides base method setting name to 'Onboarding'
   * and building state from onboarding group and item names
   *
   * @param {string} groupName - onboarding group name
   * @param {string} itemName  - onboarding item name
  ###
  @collect = (groupName, itemName) ->

    name  = 'Onboarding'
    state = "#{groupName}:#{itemName}"

    super name, state
