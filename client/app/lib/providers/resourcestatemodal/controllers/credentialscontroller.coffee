kd = require 'kd'
_  = require 'lodash'
async   = require 'async'
whoami  = require 'app/util/whoami'
globals = require 'globals'
remote  = require('app/remote').getInstance()
showError = require 'app/util/showError'
KodingKontrol = require 'app/kite/kodingkontrol'
CredentialsPageView = require '../views/stackflow/credentialspageview'
CredentialsErrorPageView = require '../views/stackflow/credentialserrorpageview'
constants = require '../constants'

module.exports = class CredentialsController extends kd.Controller

  fetchData: (callback) ->

    stack = @getData()
    queue = {
      credentials  : (next) -> helpers.loadCredentials stack, next
      requirements : (next) -> helpers.loadRequirements stack, next
      kdCmd        : (next) -> helpers.getKDCmd next
    }

    async.parallel queue, (err, results) ->
      return  if showError err

      { credentials, requirements, kdCmd } = results
      callback credentials, requirements, kdCmd


  loadData: -> @fetchData @bound 'setup'


  setup: (credentials, requirements, kdCmd) ->

    stack = @getData()
    { container } = @getOptions()

    @credentialsPage = new CredentialsPageView {}, {
      stack
      credentials  : _.extend { kdCmd }, credentials
      requirements
    }
    @errorPage = new CredentialsErrorPageView {}, { stack }

    @cacheCredentials credentials

    @forwardEvent @credentialsPage, 'InstructionsRequested'
    @credentialsPage.on 'Submitted', @bound 'onSubmitted'
    @errorPage.on 'CredentialsRequested', => container.showPage @credentialsPage

    container.appendPages @credentialsPage, @errorPage

    @emit 'ready'


  cacheCredentials: (credentials) ->

    @_credentials = {}
    credentials.items?.map (item) =>
      @_credentials[item.identifier] = item


  refresh: (credentials, requirements, kdCmd) ->

    stack = @getData()

    @credentialsPage.setData {
      stack
      credentials  : _.extend { kdCmd }, credentials
      requirements
    }

    @cacheCredentials credentials


  reloadData: -> @fetchData @bound 'refresh'


  submit: -> @credentialsPage.submit()


  onSubmitted: (submissionData) ->

    { container } = @getOptions()
    { credential, requirements } = submissionData

    queue = [
      (next) => @handleSubmittedCredential credential, next
    ]

    if requirements
      queue.push (next) => @handleSubmittedRequirements requirements, next

    async.parallel queue, @bound 'handleSubmitResult'


  handleSubmitResult: (err, identifiers) ->

    unless @showError err

      stack = @getData()

      if stack.credentials.custom?.length > 0
        identifiers.push { custom: stack.credentials.custom }

      credentials = {}
      identifiers.map (identifier) ->
        for own provider, credential of identifier
          credentials[provider] = credential

      @emit 'StartBuild', credentials

    @credentialsPage.buildButton.hideLoader()


  handleSubmittedCredential: (submissionData, callback) ->

    { computeController } = kd.singletons
    { provider, selectedItem, newData } = submissionData
    { CREDENTIAL_VERIFICATION_TIMEOUT } = constants

    pendingCredential = null

    queue = [

      (next) ->
        return next null, selectedItem  if selectedItem

        helpers.createNewCredential provider, newData, (err, newCredential) ->
          return next err  if err

          pendingCredential = newCredential
          next null, newCredential.identifier

      (identifier, next) =>

        computeController.getKloud()
          .checkCredential { provider, identifiers : [identifier] }
          .then (response) =>
            { err, verified } = @checkVerificationResult identifier, response
            next err, identifier
          .catch (err) -> next err.message
          .timeout constants.CREDENTIAL_VERIFICATION_TIMEOUT

      (identifier, next) =>

        credential = pendingCredential ? @_credentials[identifier]
        next null, identifier  unless credential

        credential.isBootstrapped (err, state) ->
          return next err  if err
          return next null, identifier  if state  # already bootstrapped

          computeController.getKloud()
            .bootstrap { identifiers: [ identifier ] }
            .then (response) -> next null, identifier
            .catch (err) -> next err.message
            .timeout constants.CREDENTIAL_BOOTSTRAP_TIMEOUT

    ]

    async.waterfall queue, (err, identifier) =>

      if err
        pendingCredential?.delete()
        callback err

      else

        if pendingCredential
          @credentialsPage.selectNewCredential pendingCredential

          { computeController } = kd.singletons
          computeController.emit 'CredentialAdded', pendingCredential

        response = {}
        response[provider] = [ identifier ]

        callback null, response


  handleSubmittedRequirements: (submissionData, callback) ->

    { provider, selectedItem, newData } = submissionData

    kallback = (identifier) ->
      callback null, { userInput: [ identifier ] }

    return kallback selectedItem  if selectedItem

    helpers.createNewCredential provider, newData, (err, newCredential) =>
      return callback err.message  if err

      @credentialsPage.selectNewRequirements newCredential

      { computeController } = kd.singletons
      computeController.emit 'CredentialAdded', newCredential

      kallback newCredential.identifier


  checkVerificationResult: (identifier, response) ->

    { CREDENTIAL_VERIFICATION_ERROR_MESSAGE } = constants

    status = response?[identifier]
    return { err : CREDENTIAL_VERIFICATION_ERROR_MESSAGE } unless status

    { verified, message } = status
    return { verified }  if verified

    return { err : CREDENTIAL_VERIFICATION_ERROR_MESSAGE }  unless message

    messageLines = message.split('\n')
    if messageLines.length > 1
      message = messageLines[..-2].join ''
    return { err : message }


  show: ->

    { container } = @getOptions()
    container.showPage @credentialsPage


  showError: (err) ->

    return no  unless err

    { container } = @getOptions()
    container.showPage @errorPage
    @errorPage.setErrors [ err ]

    return err


  helpers =

    _loadCredentials: (selector, selectedCredentials, callback) ->

      options  = { '_id' : -1 }
      remote.api.JCredential.some selector, options, (err, items) ->
        return callback err  if err

        { provider } = selector
        defaultItem  = selectedCredentials?[provider]?.first
        callback null, _.extend { items, defaultItem }, selector


    loadCredentials: (stack, callback) ->

      { requiredProviders } = stack.config

      for provider in requiredProviders
        break  if provider in ['aws', 'vagrant']
      provider ?= (Object.keys stack.credentials ? { aws : yes }).first

      helpers._loadCredentials { provider }, stack.credentials, (err, result) ->
        return callback err  if err

        { items, defaultItem } = result
        return callback null, result  unless defaultItem

        isAvailable = (
          item for item in items when item.identifier is defaultItem
        ).length > 0
        return callback null, result  if isAvailable

        # try to add stack credential to the list of credentials
        # if it's not there but it's shared with the team
        remote.api.JCredential.one defaultItem, (err, credential) ->
          return callback err, result  if err or not credential

          result.sharedCredential = credential
          callback null, result


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
