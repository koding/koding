globals = require 'globals'

module.exports = isSoloProductLite =  ->

  return no  if globals.config.environment in [ 'dev', 'sandbox' ]

  return yes
