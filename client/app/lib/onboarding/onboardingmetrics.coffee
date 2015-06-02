DatadogMetrics = require 'app/datadogmetrics'
kd = require 'kd'


module.exports = class OnboardingMetrics extends DatadogMetrics

  ###*
   * Overrides base method setting name to 'Onboarding'
   * and building state from onboarding group and item names
   *
   * @param {string} groupName - onboarding group name
   * @param {string} itemName  - onboarding item name
   * @param {number} count     - tracked count
  ###
  @collect = (groupName, itemName, count) ->

    name  = 'Onboarding'
    state = "#{groupName}:#{itemName}"

    super name, state, count


  ###*
   * Tracks onboarding item view
   *
   * @param {string} groupName - onboarding group name
   * @param {string} itemName  - onboarding item name
   * @param {number} count     - tracked time in miliseconds
  ###
  @trackView = (groupName, itemName, count) ->

    @collect groupName, "#{itemName}:viewed_in", count
