kd             = require 'kd'
whoami         = require 'app/util/whoami'
showError      = require 'app/util/showError'
CustomLinkView = require 'app/customlinkview'
KodingSwitch   = require 'app/commonviews/kodingswitch'
hasIntegration = require 'app/util/hasIntegration'

module.exports = class HomeAccountIntegrationsView extends kd.CustomHTMLView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry \
      'AppModal--account integrations', options.cssClass

    super options, data

    @linked  = {}
    @fetched = {}

    @enabledProviders = []
    for provider in ['gitlab', 'github']
      @enabledProviders.push provider  if hasIntegration provider

    mainController = kd.getSingleton 'mainController'
    for provider in @enabledProviders
      @linked[provider] = no
      foreignEvent = "ForeignAuthSuccess.#{provider}"
      mainController.on foreignEvent, @lazyBound 'handleForeignAuth', provider


  handleForeignAuth: (provider) ->

    @whenOauthInfoFetched provider, =>
      @linked[provider] = yes
      @switches[provider].setOn no


  whenOauthInfoFetched: (provider, callback) ->

    if @fetched[provider] then callback()
    else @once 'OauthInfoFetched', (_provider) ->
      do callback  if provider is _provider


  viewAppended: ->

    @addSubView loader = @getLoaderView()

    @switches = {}

    for provider in @enabledProviders
      @switches[provider] = new KodingSwitch
        cssClass: 'integration-switch'
        callback: (state) =>
          if state
            @link provider
            @switches[provider].setOn no
          else
            @unlink provider
            @switches[provider].setOff no

    me = whoami()
    me.fetchOAuthInfo (err, foreignAuth) =>

      loader.hide()

      for provider in @enabledProviders

        @addSubView container = new kd.CustomHTMLView
          cssClass: 'container'

        @linked[provider] = foreignAuth?[provider]?
        @switches[provider].setDefaultValue @linked[provider]
        @fetched[provider] = yes

        @emit 'OauthInfoFetched', provider

        container.addSubView new kd.CustomHTMLView
          partial: "#{provider.capitalize()} Integration"

        container.addSubView @switches[provider]


  link: (provider) ->

    kd.singletons.oauthController.redirectToOauthUrl { provider }


  unlink: (provider) ->

    me = whoami()
    me.unlinkOauth provider, (err) =>
      return showError err  if err

      new kd.NotificationView {
        title: "Your #{provider.capitalize()} integration is now disabled."
      }

      @linked[provider] = no


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25

