kd = require 'kd'
_  = require 'lodash'
async   = require 'async'
whoami  = require 'app/util/whoami'
globals = require 'globals'
remote  = require('app/remote').getInstance()
KodingKontrol = require 'app/kite/kodingkontrol'
CredentialsPageView = require '../views/stackflow/credentialspageview'
CredentialsErrorPageView = require '../views/stackflow/credentialserrorpageview'
constants = require '../constants'

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
      @createPages credentials, requirements, kdCmd


  createPages: (credentials, requirements, kdCmd) ->

    stack = @getData()
    { container } = @getOptions()

    @credentialsPage = new CredentialsPageView {}, {
      stack
      credentials  : _.extend { kdCmd }, credentials
      requirements
    }
    @errorPage = new CredentialsErrorPageView()

    @forwardEvent @credentialsPage, 'InstructionsRequested'
    @credentialsPage.on 'Submitted', @bound 'onSubmitted'
    @errorPage.on 'CredentialsRequested', => container.showPage @credentialsPage

    container.appendPages @credentialsPage, @errorPage

    @emit 'ready'


  submit: -> @credentialsPage.submit()


  onSubmitted: (submissionData) ->

    { container } = @getOptions()
    { credential, requirements } = submissionData

    queue = [
      (next) => @handleSubmittedCredential credential, next
    ]

    if requirements
      queue.push (next) => @handleSubmittedRequirements requirements, next

    async.parallel queue, (err, results) =>
      errs = (item.err for item in results when item.err)

      if errs.length > 0
        container.showPage @errorPage
        @errorPage.setErrors errs
      else
        identifiers = (item.identifier for item in results)
        @emit 'StartBuild', identifiers

      @credentialsPage.buildButton.hideLoader()


  handleSubmittedCredential: (submissionData, callback) ->

    { provider, selectedItem, newData } = submissionData
    { CREDENTIAL_VERIFICATION_ERROR_MESSAGE, CREDENTIAL_VERIFICATION_TIMEOUT } = constants

    pendingCredential = null

    queue = [
      (next) ->
        return next null, selectedItem  if selectedItem

        helpers.createNewCredential provider, newData, (err, newCredential) ->
          return next err  if err

          pendingCredential = newCredential
          next null, newCredential.identifier

      (identifier, next) ->

        { computeController } = kd.singletons
        computeController.getKloud()
          .checkCredential { provider, identifiers : [identifier] }
          .then (response) ->
            status = response?[identifier]
            return next CREDENTIAL_VERIFICATION_ERROR_MESSAGE  unless status

            { verified, message } = status
            return next null, identifier  if verified

            message = message.split('\n')[..-2].join ''  if message
            next message or CREDENTIAL_VERIFICATION_ERROR_MESSAGE
          .catch (err) -> next err.message
          .timeout constants.CREDENTIAL_VERIFICATION_TIMEOUT
    ]

    async.waterfall queue, (err, identifier) =>
      if err
        pendingCredential.delete()  if pendingCredential
        callback null, { err }
      else
        @credentialsPage.selectNewCredential pendingCredential  if pendingCredential
        callback null, { identifier }


  handleSubmittedRequirements: (submissionData, callback) ->

    { provider, selectedItem, newData } = submissionData

    return callback null, { identifier : selectedItem }  if selectedItem

    helpers.createNewCredential provider, newData, (err, newCredential) =>
      return callback null, { err : err.message }  if err

      @credentialsPage.selectNewRequirements newCredential
      callback null, { identifier : newCredential.identifier }


  show: ->

    { container } = @getOptions()
    container.showPage @credentialsPage


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

      whoami().fetchOtaToken (err, token) ->
        return callback err  if err

        cmd = if globals.config.environment in ['dev', 'default', 'sandbox']
        then "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
        else "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"

        callback null, cmd


    createNewCredential: (provider, newData, callback) ->

      { title, fields } = newData
      credentialData    = { provider, title, meta : fields }
      remote.api.JCredential.create credentialData, callback
