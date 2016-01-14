kd = require 'kd'

module.exports = isVideoFeatureEnabled = (callback) ->

  kd.singletons
    .mainController.isFeatureDisabled 'video-collaboration', (state) ->
      callback !state
