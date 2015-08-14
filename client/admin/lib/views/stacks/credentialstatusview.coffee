kd             = require 'kd'
JView          = require 'app/jview'
remote         = require('app/remote').getInstance()

curryIn        = require 'app/util/curryIn'
showError      = require 'app/util/showError'

CredentialSelectorModal = require './credentialselectormodal'

module.exports = class CredentialStatusView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'credential-status'

    super options, data

    { @credentials } = (@getOption 'stackTemplate') or {}
    @credentials   or= {}

    # Waiting state view
    @waitingView = new kd.View

    @waitingView.addSubView @loader  = new kd.LoaderView
      showLoader : yes
      size       : width : 16
    @waitingView.addSubView @message = new kd.CustomHTMLView
      cssClass   : 'message'
      partial    : 'Checking credentials...'

    # Stalled state view
    @stalledView = new kd.View
      cssClass   : 'hidden'

    @stalledView.addSubView @icon = new kd.CustomHTMLView
      cssClass   : 'icon not verified'

    @stalledView.addSubView @link = new kd.CustomHTMLView
      cssClass   : 'link'
      partial    : 'Credentials are not set'
      click      : =>

        modal = new CredentialSelectorModal
          selectedCredentials:
            (@credentials[val].first.identifier for val of @credentials)

        modal.on 'ItemSelected', (credential) =>

          # After adding credential, we are sharing it with the current
          # group, so anyone in this group can use this credential ~ GG
          {slug} = kd.singletons.groupsController.getCurrentGroup()
          credential.shareWith {target: slug}, (err) =>
            console.warn 'Failed to share credential:', err  if err
            @setCredential credential
            modal.destroy()


    creds = Object.keys @credentials

    if creds.length > 0
      # TODO you know it. ~GG
      credential = @credentials[creds.first].first

      remote.api.JCredential.one credential, (err, credential) =>
        if err
        then @setNotVerified 'Credentials not valid'
        else @setCredential credential
    else
      @setNotVerified()


  setCredential: (credential) ->

    return @setNotVerified()  unless credential

    creds             = {}
    @credentialsData  = [credential]
    @credentials      = creds[credential.provider] = [credential.identifier]
    {provider, title} = credential
    @setVerified "
      A credential titled as '#{title}' for #{provider} provider is selected.
    "


  setVerified: (message) ->

    @waitingView.hide()

    @setInfo message
    @link.updatePartial 'Credentials are set'
    @icon.setClass 'verified'
    @emit 'StatusChanged', 'verified'

    @stalledView.show()


  setNotVerified: (message) ->

    @waitingView.hide()

    @setInfo()
    @link.updatePartial message or 'Credentials are not set'
    @icon.unsetClass 'verified'
    @emit 'StatusChanged', 'not-verified'

    @stalledView.show()


  setInfo: (message) ->

    unless message
      return @link.unsetTooltip()

    @link.setTooltip
      title     : message
      placement : 'below'


  pistachio: ->
    """
      {{> @waitingView}}
      {{> @stalledView}}
    """
