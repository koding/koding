globals   = require 'globals'
checkFlag = require 'app/util/checkFlag'

additionalChecks =
  'gitlab' : ->
    return yes  if globals.currentGroup?.config?.gitlab?.enabled
    return globals.config.entryPoint.slug is globals.config.gitlab.team

module.exports = isFeatureEnabled = (feature) ->

  isDisabled = globals.config.disabledFeatures[feature]
  additionalChecksPassed = additionalChecks[feature]?() ? true

  # feature is not defined
  return false  unless isDisabled?

  # god mode for super-admin if additional checks passed
  return true  if checkFlag 'super-admin' and additionalChecksPassed

  # check if feature is not disabled and additional check passed
  return not isDisabled and additionalChecksPassed
