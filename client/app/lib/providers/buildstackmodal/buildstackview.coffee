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
    @credentials = new CredentialsView { provider, selectedCredential }, credentials


  pistachio: ->

    """
      <div class="section-title">Select Credential and Fill the Requirements</div>
      <div class="section-subtitle">Your stack requires AWS Credentials and a few requirements in order to boot</div>
      {{> @credentials}}
    """
