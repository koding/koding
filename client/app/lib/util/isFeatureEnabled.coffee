globals   = require 'globals'
checkFlag = require 'app/util/checkFlag'

additionalChecks =
  'gitlab' : ->
    # for now this feature is only enabled for the team defined in config
    globals.config.entryPoint.slug is globals.config.gitlab.team

module.exports = (feature) ->

  isDisabled = globals.config.disabledFeatures[feature]
  additionalCheckPassed = additionalChecks[feature]?() ? true

  # feature is not defined
  return false  unless isDisabled?

  # god mode for super-admin if additional checks passed
  return true  if checkFlag 'super-admin' and additionalCheckPassed

  # check if feature is not disabled and additional check passed
  return not isDisabled and additionalCheckPassed
