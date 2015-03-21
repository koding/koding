kd                    = require 'kd'
isLoggedIn            = require 'app/util/isLoggedIn'
showEnforceLoginModal = require 'app/util/showEnforceLoginModal'

module.exports =

  name        : 'IDE'
  behavior    : 'application'
  multiple    : yes
  dependencies: [ 'Ace', 'Finder' ]
  preCondition:
    condition  : (options, cb) -> cb isLoggedIn()
    failure    : (options, cb) ->
      kd.getSingleton('appManager').open 'IDE', conditionPassed : yes
      showEnforceLoginModal()
