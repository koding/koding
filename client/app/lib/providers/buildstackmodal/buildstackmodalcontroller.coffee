kd = require 'kd'
_  = require 'lodash'
remote = require('app/remote').getInstance()

module.exports = class BuildStackModalController extends kd.Controller

  loadCredentials: (callback) ->

    stack = @getData()
    { requiredProviders } = stack.config

    for provider in requiredProviders
      break  if provider in ['aws', 'vagrant']
    provider ?= (Object.keys stack.credentials ? { aws : yes }).first

    helper.loadCredentials { provider }, stack.credentials, callback


  loadRequirements: (callback) ->

    stack = @getData()
    { requiredProviders, requiredData } = stack.config
    provider = 'userInput'

    return callback null, { provider }  unless provider in requiredProviders

    requiredFields = requiredData[provider]
    fields = requiredFields.map (field) -> field.name ? field

    helper.loadCredentials { provider, fields }, stack.credentials, callback


  helper =

    loadCredentials: (selector, selectedCredentials, callback) ->

      options  = { '_id' : -1 }
      remote.api.JCredential.some selector, options, (err, items) ->
        return callback err  if err

        { provider } = selector
        selectedItem = selectedCredentials?[provider]?.first
        callback null, _.extend { items, selectedItem }, selector
