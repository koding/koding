debug  = (require 'debug') 'remote:api:jstacktemplate'
remote = require('../remote')

module.exports = class JStackTemplate extends remote.api.JStackTemplate


  getCredentialIdentifiers: (exclude = ['custom']) ->

    ids = []
    for provider, id of (@credentials ? {}) when provider not in exclude
      ids = ids.concat id

    return ids


  getCredentialProviders: (exclude = ['custom']) ->

    providers = []
    for provider, id of (@credentials ? {}) when provider not in exclude
      providers = providers.concat provider

    return providers


  @one = ->
    debug 'one called'
    console.trace()
    super
