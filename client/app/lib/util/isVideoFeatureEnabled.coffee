kd = require 'kd'

module.exports = isVideoFeatureEnabled = ->

  not kd.singletons.mainController.isFeatureDisabled 'video-collaboration'
