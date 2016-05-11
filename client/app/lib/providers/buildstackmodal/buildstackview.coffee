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

    @awsCredentialContainer = new kd.CustomScrollView { cssClass : 'form-scroll-wrapper' }
    awsCredentialForm = new CredentialForm {
      title : 'AWS Credential'
      selectionPlaceholder : 'Select credential...'
    }, credentials
    @awsCredentialContainer.wrapper.addSubView awsCredentialForm


  createRequirementsView: ->

    { requirements } = @getData()

    @requirementsContainer = new kd.CustomScrollView
      cssClass : 'form-scroll-wrapper requirements-wrapper'
    requirementsForm = new CredentialForm {
      title : 'Requirements'
      selectionPlaceholder : 'Select from existing requirements...'
    }, requirements
    @requirementsContainer.wrapper.addSubView requirementsForm


  pistachio: ->

    """
      <div class="top-title">Select Credential and Fill the Requirements</div>
      <div class="top-subtitle">Your stack requires AWS Credentials and a few requirements in order to boot</div>
      {{> @awsCredentialContainer}}
      {{> @requirementsContainer}}
    """
