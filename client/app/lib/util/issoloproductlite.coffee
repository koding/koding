kookies = require 'kookies'

module.exports = -> yes if kookies.get('isSoloProduct') is 'true'
