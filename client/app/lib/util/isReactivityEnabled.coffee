kd = require 'kd'
checkFlag = require 'app/util/checkFlag'

module.exports = ->

  { mainController } = kd.singletons
  isReactivityFeatureDisabled = mainController.isFeatureDisabled 'reactivity', godMode: no

  checkFlag('reactivity') and not isReactivityFeatureDisabled

