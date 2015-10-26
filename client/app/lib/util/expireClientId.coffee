kookies = require 'kookies'

module.exports = ->

  kookies.expire 'clientId'
  global.location.href = '/'
