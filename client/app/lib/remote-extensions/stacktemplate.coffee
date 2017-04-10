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
      kd.singletons.computeController.storage.stacks.push stack

      callback null, newStack


  @one = ->
    debug 'JStackTemplate.one will be deprecated!'
    super


  @some = ->
    debug 'JStackTemplate.some will be deprecated!'
    super


  @create = (options, callback) ->

    debug 'creating a stack template', options

    { storage } = kd.singletons.computeController

    super options, (err, template) ->
      return callback err  if err

      storage.templates.push template

      callback null, template


  update: (data, callback) ->

    super data, (err, updated) ->

      if not err and updated
        kd.singletons.computeController.storage.templates.push updated

      callback err, updated
