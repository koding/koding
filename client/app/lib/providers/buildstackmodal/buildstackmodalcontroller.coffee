kd = require 'kd'
remote = require('app/remote').getInstance()

module.exports = class BuildStackModalController extends kd.Controller

  constructor: (options, data) ->

    super options, data

    stack = @getData()

    for provider in stack.config?.requiredProviders
      break  if provider in ['aws', 'vagrant']
    provider ?= (Object.keys stack.credentials ? { aws : yes }).first

    @provider = provider


  loadData: (callback) ->

    selector = { provider : @provider }
    options  = { '_id' : -1 }
    remote.api.JCredential.some selector, options, callback
