kookies = require 'kookies'

module.exports = -> yes if kookies.get('isRegistrationClosed') is 'true'
