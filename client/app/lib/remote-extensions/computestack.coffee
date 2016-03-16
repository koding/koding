remote         = require('../remote').getInstance()

module.exports = class JComputeStack extends remote.api.JComputeStack

  instance: ->
    console.log this

  checkRevision: (callback) ->

    console.log 'checking revision >', this

    super callback