kd = require 'kd'
JView = require 'app/jview'
CredentialsView = require './credentialsview'

module.exports = class BuildStackView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass = 'build-stack-view'
    super options, data

    { provider } = @getOptions()
    { stack, credentials } = @getData()
    selectedCredential = stack.credentials?[provider]?.first
    @credentialsContainer = new kd.CustomScrollView { cssClass : 'form-section' }
    credentialsView = new CredentialsView { provider, selectedCredential }, credentials
    @credentialsContainer.wrapper.addSubView credentialsView


  pistachio: ->

    """
      <div class="top-title">Select Credential and Fill the Requirements</div>
      <div class="top-subtitle">Your stack requires AWS Credentials and a few requirements in order to boot</div>
      {{> @credentialsContainer}}
    """
