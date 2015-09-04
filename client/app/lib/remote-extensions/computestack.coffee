remote         = require('../remote').getInstance()

module.exports = class JComputeStack extends remote.api.JComputeStack

  bok: ->
    console.log 'lallalal'
    console.log this

  checkRevision: (callback) ->

    console.log 'checking revision ....', this

    super callback