kd = require 'kd'
isLoggedIn = require 'app/util/isLoggedIn'
showEnforceLoginModal = require 'app/util/showEnforceLoginModal'

module.exports =
  name         : 'Terminal'
  title        : 'Terminal'
  version      : '1.0.1'
  multiple     : yes
  hiddenHandle : no
  preCondition :
    condition  : (options, cb)-> cb isLoggedIn() or globals.isLoggedInOnLoad
    failure    : (options, cb)->
      kd.singletons.appManager.open 'Terminal', conditionPassed : yes
      showEnforceLoginModal()
  menu         :
    width      : 250
    items      : [
      {title: 'customViewAdvancedSettings'}
    ]
  commands     :
    'ring bell': 'ringBell'
    'noop'     : (->)
  keyBindings  : [
    { command: 'ring bell',     binding: 'alt+meta+k',        global: yes }
    { command: 'noop',          binding: ['meta+v','meta+r'], global: yes }
  ]
  behavior     : 'application'
