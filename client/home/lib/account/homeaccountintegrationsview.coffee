kd             = require 'kd'
_              = require 'lodash'
whoami         = require 'app/util/whoami'
isAdmin        = require 'app/util/isAdmin'
getGroup       = require 'app/util/getGroup'
showError      = require 'app/util/showError'
CustomLinkView = require 'app/customlinkview'
KodingSwitch   = require 'app/commonviews/kodingswitch'
hasIntegration = require 'app/util/hasIntegration'
copyToClipboard = require 'app/util/copyToClipboard'


module.exports = class HomeAccountIntegrationsView extends kd.CustomHTMLView

  # Scopes required for organizationToken integration
  # with stack templates, only valid for GitHub ~ GG
  TEAM_SCOPE = 'repo, admin:org, admin:public_key, user'
  ORG_TOKEN  = 'github.organizationToken'

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry \
      'AppModal--account integrations', options.cssClass

    super options, data

    @supportedProviders = Object.keys @providers =
      github: 'GitHub'
      gitlab: 'GitLab'

    @linked     = {}
    @linkedData = {}
    @scopes     = {}
    @tokens     = {}
    @loaders    = {}
    @toggles    = {}
    @containers = {}

    mainController = kd.getSingleton 'mainController'
    @supportedProviders.forEach (provider) =>

      @linked[provider] = no
      foreignEvent = "ForeignAuthSuccess.#{provider}"
      mainController.on foreignEvent, @lazyBound 'handleForeignAuth', provider

      @toggles[provider] = new KodingSwitch
        cssClass: 'integration-switch'
        callback: (state) =>
          if state
            @link provider
            @toggles[provider].setOn no
          else
            @unlink provider
            @toggles[provider].setOff no

      @toggles[provider].makeDisabled()

      @addSubView @containers[provider] = new kd.CustomHTMLView
        cssClass: 'container hidden'

      @containers[provider].addSubView @tokens[provider] = new kd.CustomHTMLView
        partial: "#{@providers[provider]} Integration"
        click: (event) ->
          if event.target.tagName is 'CITE'
            copyToClipboard @getElement().querySelector 'token'

      @containers[provider].addSubView @scopes[provider] = new kd.CustomHTMLView
        cssClass: 'scope hidden'
        partial: ''

      @containers[provider].addSubView @toggles[provider]

      @containers[provider].addSubView @loaders[provider] = @getLoaderView()


  handleForeignAuth: (provider) -> @fetchOAuthInfo =>

    return  unless @linked[provider]

    if provider is 'github' and isAdmin()
      { scope, token } = @linkedData[provider]
      if @isTeamScope scope
        group = getGroup()
        group.fetchDataAt ORG_TOKEN, (err, existingToken) ->
          return  if err or existingToken
          data = {}
          data[ORG_TOKEN] = token
          group.modifyData data, (err) ->
            console.log 'Set team organization key failed:', err  if err

    kd.utils.defer => new kd.NotificationView
      title: "Your #{@providers[provider]} integration is now enabled."


  viewAppended: ->

    @fetchOAuthInfo()


  fetchOAuthInfo: (callback = kd.noop) ->

    me = whoami()
    me.fetchOAuthInfo (err, foreignAuth) =>
      return showError err  if err

      @supportedProviders.forEach (provider) =>

        { loader, toggle, scope, token, title } = @getDetails provider

        @linked[provider] = foreignAuth?[provider]?
        toggle.setDefaultValue @linked[provider]
        toggle.makeEnabled()
        loader.hide()

        @linkedData[provider] = foreignAuth?[provider] ? {}

        if @linked[provider] and existingScope = foreignAuth[provider].scope
          existingScope = existingScope.replace /,/g, ', '
          scope.updatePartial existingScope
          scope.setTooltip
            title: "Scopes: #{existingScope}"
          scope.show()
          token.updatePartial "
            #{title} Integration
            <cite>COPY TOKEN</cite>
            <token>#{@linkedData[provider].token}</token>
          "
        else
          scope.unsetTooltip()
          scope.hide()
          token.updatePartial "#{title} Integration"

      do callback


  show: ->

    super

    for provider in @supportedProviders
      if hasIntegration provider
      then @containers[provider].show()
      else @containers[provider].hide()


  link: (provider) ->

    { loader, toggle, title } = @getDetails provider

    loader.show()

    options  = { provider }
    redirect = ->
      kd.singletons.oauthController.redirectToOauthUrl options
      new kd.NotificationView
        title    : "Redirecting to #{title}..."
        duration : 0

    if provider is 'github' and isAdmin()
      group = getGroup()
      group.fetchDataAt ORG_TOKEN, (err, token) ->
        return redirect()  if err or token

        scope = TEAM_SCOPE
        cc = kd.singletons.computeController
        cc.ui.askFor 'enableTeamOAuth', { scope }, (status) ->
          if status.cancelled
            toggle.setOff no
            loader.hide()
          else
            options.scope = scope  if status.confirmed
            redirect()

    else
      redirect()


  unlink: (provider) ->

    { loader, toggle, scope, token, title } = @getDetails provider

    loader.show()

    me = whoami()
    unlink = => me.unlinkOauth provider, (err) =>
      if err
        toggle.setOn no
        loader.hide()
        return showError err

      new kd.NotificationView
        title: "Your #{title} integration is now disabled."

      @linked[provider] = no
      scope.unsetTooltip()
      scope.hide()

      token.updatePartial "#{title} Integration"

      loader.hide()

    if provider is 'github' and isAdmin()

      group = getGroup()
      group.fetchDataAt ORG_TOKEN, (err, existingToken) =>
        return unlink()  if err or not existingToken

        if existingToken is @linkedData.github.token

          cc = kd.singletons.computeController
          cc.ui.askFor 'disableTeamOAuth', {}, (status) ->

            if status.confirmed
              data = {}
              data[ORG_TOKEN] = null
              group.modifyData data, (err) ->
                console.log 'Removing team organization key failed:', err  if err
              do unlink

            else
              toggle.setOn no
              loader.hide()
        else
          do unlink

    else
      do unlink


  getLoaderView: ->

    new kd.LoaderView
      showLoader : yes
      size       :
        width    : 12
        height   : 12


  isTeamScope: (scope) ->

    _.isEqual scope.split(',').sort(), TEAM_SCOPE.split(', ').sort()


  getDetails : (provider) ->
    title  : @providers[provider]
    loader : @loaders[provider]
    toggle : @toggles[provider]
    scope  : @scopes[provider]
    token  : @tokens[provider]
