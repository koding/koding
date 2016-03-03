globals = require 'globals'

module.exports = isSoloProductLite =  ->

  return no  if globals.config.environment in [ 'dev', 'sandbox' ]

  cutOffDate = new Date 2016, 2, 1  # March 1st, 2016

  return Date.now() > cutOffDate.getTime()