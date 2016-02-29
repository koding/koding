DatadogMetrics = require 'app/datadogmetrics'


module.exports = class OnboardingMetrics extends DatadogMetrics

  ###*
   * Overrides base method setting name to 'Onboarding'
   * and building state from onboarding and item names
   *
   * @param {string} onboardingName - onboarding name
   * @param {string} itemName       - onboarding item name
   * @param {number} count          - tracked count
  ###
  @collect = (onboardingName, itemName, count) ->

    name  = 'Onboarding'
    state = "#{onboardingName}:#{itemName}"

    super name, state, count


  ###*
   * Tracks onboarding item view
   *
   * @param {string} onboardingName - onboarding name
   * @param {string} itemName       - onboarding item name
   * @param {number} count          - tracked time in miliseconds
  ###
  @trackView = (onboardingName, itemName, count) ->

    @collect onboardingName, "#{itemName}:viewed_in", count
