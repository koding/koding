checkFlag = require './checkFlag'

module.exports = isVideoFeatureEnabled = ->

  # for now we are only allowing super-admins to start video chat.
  # After we release it publicly, we only need to change the logic here. ~Umut
  checkFlag 'super-admin'

