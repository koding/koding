kookies = require 'kookies'
isLoggedIn = require './isLoggedIn'
kd = require 'kd'

module.exports = ->

  return  if isLoggedIn()
  if kookies.get('doNotForceRegistration') or global.location.search.indexOf('sr=1') > -1
    kookies.set 'doNotForceRegistration', 'true'
    return

  kd.singletons.appManager.tell 'Account', 'showRegistrationNeededModal'
