globals   = require 'globals'
checkFlag = require 'app/util/checkFlag'

module.exports = (feature) ->

  isDisabled = globals.config.disabledFeatures[feature]

  # feature is not defined
  return false  unless isDisabled?

  # god mode for super-admin
  return true  if checkFlag 'super-admin'

  return not isDisabled
