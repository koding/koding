debug  = (require 'debug') 'remote:api:jstacktemplate'

kd = require 'kd'
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


  generateStack: (options, callback) ->

    debug 'generateStack called', options

    super options, (err, newStack) ->

      debug 'generateStack res:', err, newStack
      return callback err  if err

      { results: { machines }, stack } = newStack
      stack.machines = machines.map (m) -> m.obj
      kd.singletons.computeController.storage.push 'stacks', stack

      callback null, newStack


  @one = ->
    console.warn 'JStackTemplate.one will be deprecated!'
    super


  @some = ->
    console.warn 'JStackTemplate.some will be deprecated!'
    super
