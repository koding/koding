remote = require('../remote')

module.exports = class JStackTemplate extends remote.api.JStackTemplate


  getCredentialIdentifiers: ->

    ids = []
    ids = ids.concat id  for provider, id of (@credentials ? {})

    return ids
