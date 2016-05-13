kd = require 'kd'
async = require 'async'
remote = require('app/remote').getInstance()
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'
CredentialForm = require './credentialform'
KDCredentialForm = require './kdcredentialform'
showError = require 'app/util/showError'

module.exports = class CredentialsPageView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @progressPane = new WizardProgressPane
      currentStep : WizardSteps.Credentials

    @createCredentialView()
    @createRequirementsView()

    @backLink = new kd.CustomHTMLView
      tagName  : 'a'
      cssClass : 'back-link'
      partial  : '<span class="arrow"></span>  BACK TO INSTRUCTIONS'
      click    : @lazyBound 'emit', 'InstructionsRequested'

    @buildButton = new kd.ButtonView
      title    : 'Build Stack'
      cssClass : 'GenericButton'
      loader   : yes
      callback : @bound 'onBuild'


  createCredentialView: ->

    { credentials } = @getData()
    { provider }    = credentials

    @credentialContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper credential-wrapper'

    options   = helper.getFormOptions provider
    formClass = if provider is 'vagrant' then KDCredentialForm else CredentialForm
    @credentialForm = new formClass options, credentials
    @credentialContainer.wrapper.addSubView @credentialForm


  createRequirementsView: ->

    { requirements } = @getData()

    @requirementsContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper requirements-wrapper'

    return @setClass 'credential-only'  unless requirements.fields

    options = helper.getFormOptions requirements.provider
    @requirementsForm = new CredentialForm options, requirements
    @requirementsContainer.wrapper.addSubView @requirementsForm


  onBuild: ->

    validationQueue =
      credential    : helper.createFormValidationCallback @credentialForm
      requirements  : helper.createFormValidationCallback @requirementsForm

    async.parallel validationQueue, (err, validationResults) =>
      return @buildButton.hideLoader()  if err

      resultQueue = [
        helper.createFormResultCallback validationResults.credential
        helper.createFormResultCallback validationResults.requirements
      ]

      async.series resultQueue, (err, identifiers) =>
        if err
          @buildButton.hideLoader()
          return showError err

        alert identifiers


  pistachio: ->

    { title, description } = helper.getTitleAndDescription @getData()

    """
      <div class="credentials-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="main">
          <h2>#{title}</h2>
          <p>#{description}</p>
          {{> @credentialContainer}}
          {{> @requirementsContainer}}
          <div class="clearfix"></div>
        </section>
        <footer>
          {{> @backLink}}
          {{> @buildButton}}
        </footer>
      </div>
    """

  helper =

    getFormOptions: (provider) ->

      switch provider
        when 'vagrant'
          title : 'KD Local Host'
          selectionLabel : 'KD Selection'
          selectionPlaceholder : 'Select your existent KD...'
        when 'aws'
          title : 'AWS Credential'
          selectionLabel : 'Credential Selection'
          selectionPlaceholder : 'Select credential...'
        when 'userInput'
          title : 'Requirements'
          selectionLabel : 'Requirement Selection'
          selectionPlaceholder : 'Select from existing requirements...'


    getTitleAndDescription: (data) ->

      { credentials, requirements } = data
      if not credentials.items.length and not requirements.fields
        return {
          title       : 'Create Your First Credential'
          description : '''
            Your Credential provides Koding with all of the information it needs to build your Stack
          '''
        }

      return {
        title       : 'Select Credential and Fill the Requirements'
        description : '''
          Your stack requires AWS Credentials and a few requirements in order to boot
        '''
      }


    createFormValidationCallback: (form) ->

      (next) ->

        return next()  unless form

        form.off  'FormValidationPassed'
        form.once 'FormValidationPassed', (result) ->
          next null, result

        form.off  'FormValidationFailed'
        form.once 'FormValidationFailed', -> next 'ValidationError'

        form.validate()


    createFormResultCallback: (validationResult) ->

      (next) ->

        return next()  unless validationResult

        { selectedItem, newData } = validationResult
        return next null, selectedItem  if selectedItem

        remote.api.JCredential.create newData, (err, credential) ->
          return next err  if err
          return next null, credential.identifier
