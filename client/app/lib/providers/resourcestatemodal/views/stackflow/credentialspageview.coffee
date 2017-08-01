kd = require 'kd'
async = require 'async'

globals = require 'globals'
CredentialForm = require './credentialform'
KDCredentialForm = require './kdcredentialform'

module.exports = class CredentialsPageView extends kd.View

  SHARED_CREDENTIAL_TITLE = 'Use default credential'

  constructor: (options = {}, data) ->

    super options, data

    @createRequirementsView()
    @createCredentialView()

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>Back to Instructions'
      click    : @lazyBound 'emit', 'InstructionsRequested'

    @buildButton = new kd.ButtonView
      title    : 'Build Stack'
      cssClass : 'GenericButton'
      loader   : yes
      callback : @bound 'submit'


  setData: (data) ->

    super data

    return  unless @credentialForm

    { credentials, requirements } = @getData()
    { provider, items, sharedCredential } = credentials

    @addSharedCredential items, sharedCredential

    @credentialForm.setData credentials
    @requirementsForm.setData requirements


  createRequirementsView: ->

    { requirements } = @getData()

    if not requirements.fields
      return @requirementsForm = new kd.CustomHTMLView { cssClass : 'hidden' }

    options = helpers.getFormOptions requirements.provider
    options.cssClass = 'right-form'
    @requirementsForm = new CredentialForm options, requirements


  createCredentialView: ->

    { credentials } = @getData()
    { provider, items, sharedCredential } = credentials

    @addSharedCredential items, sharedCredential

    options = helpers.getFormOptions provider
    options.cssClass = 'left-form'  unless @requirementsForm.hasClass 'hidden'
    formClass = if provider is 'vagrant' then KDCredentialForm else CredentialForm
    @credentialForm = new formClass options, credentials


  addSharedCredential: (items, sharedCredential) ->

    return  unless sharedCredential
    return  if items.first?.title is SHARED_CREDENTIAL_TITLE

    sharedCredential.title = SHARED_CREDENTIAL_TITLE
    sharedCredential.isLocked = yes
    items.unshift sharedCredential


  submit: ->

    queue =
      credential   : helpers.createValidationCallback @credentialForm
      requirements : helpers.createValidationCallback @requirementsForm

    async.parallel queue, (err, validationResults) =>
      return @buildButton.hideLoader()  if err
      @emit 'Submitted', validationResults


  selectNewCredential: (data) ->

    { credentials } = @getData()
    credentials.items.push data
    @credentialForm.setData credentials
    @credentialForm.selectValue data.identifier


  selectNewRequirements: (data) ->

    { requirements } = @getData()
    requirements.items.push data
    @requirementsForm.setData requirements
    @requirementsForm.selectValue data.identifier


  pistachio: ->

    { title, description } = helpers.getTitleAndDescription @getData()

    """
      <div class="credentials-page">
        <section class="main">
          <h2>#{title}</h2>
          <p>#{description}</p>
          {{> @credentialForm}}
          {{> @requirementsForm}}
          <div class="clearfix"></div>
        </section>
        <footer>
          {{> @backLink}}
          {{> @buildButton}}
        </footer>
      </div>
    """

  helpers =

    getFormOptions: (provider) ->

      switch provider
        when 'vagrant'
          title : helpers.getCredentialsTitle provider
          selectionLabel : 'KD Selection'
          selectionPlaceholder : 'Select your existent KD...'
        when 'userInput'
          title : 'Requirements'
          selectionLabel : 'Requirement Selection'
          selectionPlaceholder : 'Select from existing requirements...'
        else
          title : helpers.getCredentialsTitle provider
          selectionLabel : 'Credential Selection'
          selectionPlaceholder : 'Select credential...'


    getTitleAndDescription: (data) ->

      { credentials, requirements } = data
      { provider } = credentials

      hasCredentials  = credentials.items.length > 0
      hasRequirements = requirements.fields?
      title = switch
        when not hasCredentials and not hasRequirements then 'Create Credentials'
        when not hasRequirements then 'Select Credentials'
        else 'Select Credentials and Other Requirements'

      description  = "Your stack requires a #{helpers.getCredentialsTitle provider} "
      description += 'and a few requirements '  if requirements.fields
      description += 'in order to boot'

      return { title, description }


    getCredentialsTitle: (provider) ->

      globals.config.providers[provider]?.title ? ''


    createValidationCallback: (form) ->

      (next) ->

        return next()  if form.hasClass 'hidden'

        form.off  'FormValidationPassed'
        form.once 'FormValidationPassed', (result) ->
          next null, result

        form.off  'FormValidationFailed'
        form.once 'FormValidationFailed', -> next 'ValidationError'

        form.validate()
