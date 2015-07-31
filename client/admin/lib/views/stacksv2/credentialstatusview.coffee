kd             = require 'kd'
JView          = require 'app/jview'

curryIn        = require 'app/util/curryIn'
showError      = require 'app/util/showError'

CredentialSelectorModal = require './credentialselectormodal'

module.exports = class CredentialStatusView extends kd.View

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    curryIn options, cssClass: 'credential-status'

    super options, data

    @credentials = []

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

        modal = new CredentialSelectorModal {
          selectedCredentials: @getPublicKeys()
        }

        modal.on 'ItemSelected', (credential) =>
          modal.destroy()

          @setCredential credential


  setCredential: (credential) ->

    return @setNotVerified()  unless credential

    @credentials      = [credential]
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
    @link.updatePartial 'Credentials are not set'
    @icon.unsetClass 'verified'
    @emit 'StatusChanged', 'not-verified'

    @stalledView.show()


  setInfo: (message) ->

    unless message
      return @link.unsetTooltip()

    @link.setTooltip
      title     : message
      placement : 'below'


  getPublicKeys: ->
    (cred.publicKey for cred in @credentials)


  pistachio: ->
    """
      {{> @waitingView}}
      {{> @stalledView}}
    """
