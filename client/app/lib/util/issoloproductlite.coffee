kookies = require 'kookies'

module.exports = isSoloProductLite =  ->

  return if kookies.get('isRegistrationClosed') is 'true'