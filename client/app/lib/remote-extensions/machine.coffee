kd             = require 'kd'
remote         = require('../remote').getInstance()
Machine        = require 'app/providers/machine'


module.exports = class JMachine extends remote.api.JMachine

  stop: ->
    kd.singletons.computeController.stop new Machine { machine: this }

  start: ->
    kd.singletons.computeController.start new Machine { machine: this }
