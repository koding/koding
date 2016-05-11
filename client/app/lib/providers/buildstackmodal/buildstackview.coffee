kd = require 'kd'
JView = require 'app/jview'
CredentialForm = require './credentialform'

module.exports = class BuildStackView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'build-stack-view'
    super options, data

    @createCredentialView()
    @createRequirementsView()


  createCredentialView: ->

    { credentials } = @getData()

    @awsCredentialContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper credential-wrapper'
    awsCredentialForm = new CredentialForm {
      title : 'AWS Credential'
      selectionPlaceholder : 'Select credential...'
      selectionLabel : 'Credential Selection'
    }, credentials
    @awsCredentialContainer.wrapper.addSubView awsCredentialForm


  createRequirementsView: ->

    { requirements } = @getData()

    @requirementsContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper requirements-wrapper'

    return @setClass 'credential-only'  unless requirements.fields

    requirementsForm = new CredentialForm {
      title : 'Requirements'
      selectionPlaceholder : 'Select from existing requirements...'
      selectionLabel : 'Requirement Selection'
    }, requirements
    @requirementsContainer.wrapper.addSubView requirementsForm


  buildTitleAndDescription: ->

    { credentials, requirements } = @getData()

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


  pistachio: ->

    { title, description } = @buildTitleAndDescription()

    """
      <div class="top-title">#{title}</div>
      <div class="top-subtitle">#{description}</div>
      {{> @awsCredentialContainer}}
      {{> @requirementsContainer}}
    """
