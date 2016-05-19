kd = require 'kd'
async = require 'async'
JView = require 'app/jview'
WizardSteps = require './wizardsteps'
WizardProgressPane = require './wizardprogresspane'
CredentialForm = require './credentialform'
KDCredentialForm = require './kdcredentialform'

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
      partial  : '<span class="arrow"></span>Back to Instructions'
      click    : @lazyBound 'emit', 'InstructionsRequested'

    @buildButton = new kd.ButtonView
      title    : 'Build Stack'
      cssClass : 'GenericButton'
      loader   : yes
      callback : @bound 'submit'


  createCredentialView: ->

    { credentials } = @getData()
    { provider }    = credentials

    @credentialContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper credential-wrapper'

    options   = helpers.getFormOptions provider
    formClass = if provider is 'vagrant' then KDCredentialForm else CredentialForm
    @credentialForm = new formClass options, credentials
    @credentialContainer.wrapper.addSubView @credentialForm


  createRequirementsView: ->

    { requirements } = @getData()

    @requirementsContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper requirements-wrapper'

    return  unless requirements.fields

    options = helpers.getFormOptions requirements.provider
    @requirementsForm = new CredentialForm options, requirements
    @requirementsContainer.wrapper.addSubView @requirementsForm


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
    credentials.selectedItem = data.identifier
    @credentialForm.setData credentials


  selectNewRequirements: (data) ->

    { requirements } = @getData()
    requirements.items.push data
    requirements.selectedItem = data.identifier
    @requirementsForm.setData requirements


  pistachio: ->

    { title, description } = helpers.getTitleAndDescription @getData()

    { requirements }   = @getData()
    containerCssClass  = 'main'
    containerCssClass += ' credential-only' unless requirements.fields

    """
      <div class="credentials-page">
        <header>
          <h1>Build Your Stack</h1>
        </header>
        {{> @progressPane}}
        <section class="#{containerCssClass}">
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

  helpers =

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


    createValidationCallback: (form) ->

      (next) ->

        return next()  unless form

        form.off  'FormValidationPassed'
        form.once 'FormValidationPassed', (result) ->
          next null, result

        form.off  'FormValidationFailed'
        form.once 'FormValidationFailed', -> next 'ValidationError'

        form.validate()
