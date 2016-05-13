kd = require 'kd'
_  = require 'lodash'
whoami  = require 'app/util/whoami'
globals = require 'globals'
remote  = require('app/remote').getInstance()
KodingKontrol = require 'app/kite/kodingkontrol'

module.exports = class BuildStackModalController extends kd.Controller

  loadStackTemplate: (callback) ->

    stack = @getData()
    { computeController } = kd.singletons

    computeController.fetchBaseStackTemplate stack, callback


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


  getKDCmd: (callback) ->

    whoami().fetchOtaToken (err, token) =>
      return callback err  if err

      cmd = if globals.config.environment in ['dev', 'default', 'sandbox']
        "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
      else
        "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"

      callback null, cmd


  helper =

    loadCredentials: (selector, selectedCredentials, callback) ->

      options  = { '_id' : -1 }
      remote.api.JCredential.some selector, options, (err, items) ->
        return callback err  if err

        { provider } = selector
        selectedItem = selectedCredentials?[provider]?.first
        callback null, _.extend { items, selectedItem }, selector
