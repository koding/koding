kd = require 'kd'
_  = require 'lodash'
async   = require 'async'
whoami  = require 'app/util/whoami'
globals = require 'globals'
remote  = require('app/remote').getInstance()
KodingKontrol = require 'app/kite/kodingkontrol'
CredentialsPageView = require '../views/credentialspageview'

module.exports = class CredentialsController extends kd.Controller

  constructor: (options, data) ->

    super options, data
    @loadData()


  loadData: ->

    stack = @getData()
    queue = {
      credentials  : (next) -> helpers.loadCredentials stack, next
      requirements : (next) -> helpers.loadRequirements stack, next
      kdCmd        : (next) -> helpers.getKDCmd next
    }

    async.parallel queue, (err, results) =>
      return showError err  if err

      { credentials, requirements, kdCmd } = results
      @delegate.addSubView @view = new CredentialsPageView { cssClass : 'hidden' }, {
        stack
        credentials  : _.extend { kdCmd }, credentials
        requirements
      }
      @forwardEvent @view, 'InstructionsRequested'
      @view.on 'Submitted', @bound 'onSubmitted'


  onSubmitted: (formData) ->

    { credential, requirements } = formData

    queue = [ helpers.createSubmittionCallback credential ]
    queue.push helpers.createSubmittionCallback requirements  if requirements

    async.series queue, (err, identifiers) =>
      if err
        return showError err

      alert identifiers


  show: -> @view.show()


  hide: -> @view.hide()


  helpers =

    _loadCredentials: (selector, selectedCredentials, callback) ->

      options  = { '_id' : -1 }
      remote.api.JCredential.some selector, options, (err, items) ->
        return callback err  if err

        { provider } = selector
        selectedItem = selectedCredentials?[provider]?.first
        callback null, _.extend { items, selectedItem }, selector


    loadCredentials: (stack, callback) ->

      { requiredProviders } = stack.config

      for provider in requiredProviders
        break  if provider in ['aws', 'vagrant']
      provider ?= (Object.keys stack.credentials ? { aws : yes }).first

      helpers._loadCredentials { provider }, stack.credentials, callback


    loadRequirements: (stack, callback) ->

      { requiredProviders, requiredData } = stack.config
      provider = 'userInput'

      return callback null, { provider }  unless provider in requiredProviders

      requiredFields = requiredData[provider]
      fields = requiredFields.map (field) -> field.name ? field

      helpers._loadCredentials { provider, fields }, stack.credentials, callback


    getKDCmd: (callback) ->
    
      whoami().fetchOtaToken (err, token) =>
        return callback err  if err
    
        cmd = if globals.config.environment in ['dev', 'default', 'sandbox']
        then "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
        else "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"
    
        callback null, cmd


    createSubmittionCallback: (formData) ->

      (next) ->

        return next()  unless formData

        { selectedItem, newData } = formData
        return next null, selectedItem  if selectedItem

        return next null, '12345'
        remote.api.JCredential.create newData, (err, credential) ->
          return next err  if err
          return next null, credential.identifier
