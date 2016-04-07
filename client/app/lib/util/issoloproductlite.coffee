globals = require 'globals'

module.exports = isSoloProductLite =  ->

  return no  if globals.config.environment in [ 'dev', 'default', 'sandbox' ]

  return yes
