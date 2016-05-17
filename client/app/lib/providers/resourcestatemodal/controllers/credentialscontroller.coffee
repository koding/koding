kd = require 'kd'
_  = require 'lodash'
async   = require 'async'
whoami  = require 'app/util/whoami'
globals = require 'globals'
remote  = require('app/remote').getInstance()
KodingKontrol = require 'app/kite/kodingkontrol'
CredentialsPageView = require '../views/credentialspageview'
CredentialsErrorPageView = require '../views/credentialserrorpageview'
commonHelpers = require '../helpers'

module.exports = class CredentialsController extends kd.Controller

  DEFAULT_VERIFICATION_ERROR_MESSAGE = '''
    We couldn't verify this credential, please check the ones you
    used or add a new credential to be able to continue to the
    next step.
  '''
  VERIFICATION_TIMEOUT = 10000

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
      @emit 'ready'


  createPages: (credentials, requirements, kdCmd) ->

    stack = @getData()
    { container } = @getOptions()

    container.addSubView @credentialsPage = new CredentialsPageView {}, {
      stack
      credentials  : _.extend { kdCmd }, credentials
      requirements
    }
    @credentialsPage.hide()
    @forwardEvent @credentialsPage, 'InstructionsRequested'
    @credentialsPage.on 'Submitted', @bound 'onSubmitted'

    container.addSubView @errorPage = new CredentialsErrorPageView()
    @errorPage.hide()
    @errorPage.on 'CredentialsRequested', =>
      commonHelpers.changePage @errorPage, @credentialsPage


  onSubmitted: (submissionData) ->

    { credential, requirements } = submissionData

    queue = [
      (next) => @handleSubmittedCredential credential, next
    ]

    if requirements
      queue.push (next) => @handleSubmittedRequirements requirements, next

    async.parallel queue, (err, results) =>
      errs = (item.err for item in results when item.err)

      if errs.length > 0
        commonHelpers.changePage @credentialsPage, @errorPage
        @errorPage.setErrors errs
        @credentialsPage.buildButton.hideLoader()
      else
        stack = @getData()
        identifiers = (item.identifier for item in results)
        { computeController } = kd.singletons

        computeController.buildStack stack, identifiers
        @emit 'NextPageRequested'


  handleSubmittedCredential: (submissionData, callback) ->

    { provider, selectedItem, newData } = submissionData

    queue = [
      (next) =>
        return next null, selectedItem  if selectedItem

        helpers.createNewCredential provider, newData, (err, newCredential) =>
          return next err  if err

          @credentialsPage.selectNewCredential newCredential
          next null, newCredential.identifier

      (identifier, next) ->

        { computeController } = kd.singletons
        computeController.getKloud()
          .checkCredential { provider, identifiers : [identifier] }
          .then (response) ->
            next null, { identifier, status : response?[identifier] }
          .catch (err) -> next err
          .timeout VERIFICATION_TIMEOUT
    ]

    async.waterfall queue, (err, result) =>
      return callback null, { err : err.message }  if err
      return callback null, { err : DEFAULT_VERIFICATION_ERROR_MESSAGE }  unless result.status

      { identifier, status } = result
      { verified, message }  = status
      message = message.split('\n')[..-2].join ''  if message
      if verified
        callback null, { identifier }
      else
        callback null, {
          err : message or DEFAULT_VERIFICATION_ERROR_MESSAGE
        }


  handleSubmittedRequirements: (submissionData, callback) ->

    { provider, selectedItem, newData } = submissionData

    return callback null, { identifier : selectedItem }  if selectedItem

    helpers.createNewCredential provider, newData, (err, newCredential) =>
      return callback null, { err : err.message }  if err

      @credentialsPage.selectNewRequirements newCredential
      callback null, { identifier : newCredential.identifier }


  show: ->

    @ready => @credentialsPage.show()


  hide: ->

    @credentialsPage.hide()
    @errorPage.hide()


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


    createNewCredential: (provider, newData, callback) ->

      { title, fields } = newData
      credentialData    = { provider, title, meta : fields }
      remote.api.JCredential.create credentialData, callback
