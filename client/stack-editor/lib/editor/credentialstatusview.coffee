kd             = require 'kd'
KDView         = kd.View

remote         = require 'app/remote'
curryIn        = require 'app/util/curryIn'


module.exports = class CredentialStatusView extends KDView



  constructor: (options = {}, data) ->

    curryIn options, { cssClass: 'credential-status' }

    super options, data

    { @credentials } = (@getOption 'stackTemplate') or {}
    @credentials   or= {}
    @credentialsData = []

    # Waiting state view
    @waitingView = new KDView

    @waitingView.addSubView @loader  = new kd.LoaderView
      showLoader : yes
      size       : { width : 16 }

    @waitingView.addSubView @message = new kd.CustomHTMLView
      cssClass   : 'message'
      partial    : 'Checking credentials...'

    # Stalled state view
    @stalledView = new KDView
      cssClass   : 'hidden'

    @stalledView.addSubView @icon = new kd.CustomHTMLView
      cssClass   : 'icon not verified'

    @stalledView.addSubView @link = new kd.CustomHTMLView
      cssClass   : 'link'
      partial    : 'Credentials are not set'

    { selectedProvider } = @getOptions()
    creds = Object.keys @credentials

    if creds.length > 0 and credential = @credentials[selectedProvider]?.first
      remote.api.JCredential.one credential, (err, credential) =>
        if err or not credential
        then @setNotVerified 'Credentials not valid'
        else @setCredential credential
    else
      @setNotVerified()


  setCredential: (credential) ->

    return @setNotVerified()  unless credential

    creds               = {}
    @credentialsData    = [credential]
    @credentials        = creds[credential.provider] = [credential.identifier]
    { provider, title } = credential
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
    kd.utils.defer => @emit 'StatusChanged', 'not-verified'

    @stalledView.show()


  setInfo: (message) ->

    unless message
      return @link.unsetTooltip()

    @link.setTooltip
      title     : message
      placement : 'below'


  pistachio: ->
    '''
      {{> @waitingView}}
      {{> @stalledView}}
    '''
