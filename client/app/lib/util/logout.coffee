kd = require 'kd'
globals = require 'globals'

module.exports = ->
  mainController = kd.getSingleton('mainController')
  mainController.isLoggingIn on
  delete globals.userAccount
