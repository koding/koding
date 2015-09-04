kd             = require 'kd'
remote         = require('../remote').getInstance()

module.exports = class JMachine extends remote.api.JMachine

  stop: ->
    kd.singletons.computeController.stop this

  start: ->
    kd.singletons.computeController.start this
