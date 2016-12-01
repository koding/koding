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

    @supportedProviders = ['gitlab', 'github']

    @switches   = {}
    @containers = {}

    mainController = kd.getSingleton 'mainController'
    @supportedProviders.forEach (provider) =>

      @linked[provider] = no
      foreignEvent = "ForeignAuthSuccess.#{provider}"
      mainController.on foreignEvent, @lazyBound 'handleForeignAuth', provider

      @switches[provider] = new KodingSwitch
        cssClass: 'integration-switch'
        callback: (state) =>
          if state
            @link provider
            @switches[provider].setOn no
          else
            @unlink provider
            @switches[provider].setOff no

      @switches[provider].makeDisabled()

      @addSubView @containers[provider] = new kd.CustomHTMLView
        cssClass: 'container hidden'

      @containers[provider].addSubView new kd.CustomHTMLView
        partial: "#{provider.capitalize()} Integration"

      @containers[provider].addSubView @switches[provider]


  handleForeignAuth: (provider) ->

    @whenOauthInfoFetched provider, =>
      kd.utils.defer -> new kd.NotificationView
        title: "Your #{provider.capitalize()} integration is now enabled."
      @linked[provider] = yes
      @switches[provider].setOn no


  whenOauthInfoFetched: (provider, callback) ->

    if @fetched[provider]
      do callback
    else
      @once "OauthInfoFetched.#{provider}", callback


  viewAppended: ->

    me = whoami()
    me.fetchOAuthInfo (err, foreignAuth) =>
      return showError err  if err

      @supportedProviders.forEach (provider) =>

        @linked[provider] = foreignAuth?[provider]?
        @switches[provider].setDefaultValue @linked[provider]
        @switches[provider].makeEnabled()
        @fetched[provider] = yes

        @emit "OauthInfoFetched.#{provider}"


  show: ->

    super

    for provider in @supportedProviders
      if hasIntegration provider
      then @containers[provider].show()
      else @containers[provider].hide()


  link: (provider) ->

    kd.singletons.oauthController.redirectToOauthUrl { provider }


  unlink: (provider) ->

    me = whoami()
    me.unlinkOauth provider, (err) =>
      return showError err  if err

      new kd.NotificationView
        title: "Your #{provider.capitalize()} integration is now disabled."

      @linked[provider] = no


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25

