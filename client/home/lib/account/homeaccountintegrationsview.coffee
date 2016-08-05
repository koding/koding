kd             = require 'kd'
whoami         = require 'app/util/whoami'
showError      = require 'app/util/showError'
CustomLinkView = require 'app/customlinkview'
KodingSwitch   = require 'app/commonviews/kodingswitch'

module.exports = class HomeAccountIntegrationsView extends kd.CustomHTMLView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry \
      'AppModal--account integrations', options.cssClass

    super options, data

    mainController = kd.getSingleton 'mainController'
    mainController.on 'ForeignAuthSuccess.gitlab', =>
      @whenOauthInfoFetched =>
        @linked = yes
        @switch.setOn no


  whenOauthInfoFetched: (callback) ->

    if @fetched then callback()
    else @once 'OauthInfoFetched', callback


  viewAppended: ->

    @addSubView loader = @getLoaderView()

    @switch = new KodingSwitch
      cssClass: 'integration-switch'
      callback: (state) =>
        if state
          @link()
          @switch.setOn no
        else
          @unlink()
          @switch.setOff no

    me = whoami()
    me.fetchOAuthInfo (err, foreignAuth) =>

      loader.hide()

      @linked = foreignAuth?.gitlab?
      @switch.setDefaultValue @linked

      @fetched = yes
      @emit 'OauthInfoFetched'

      @addSubView new kd.CustomHTMLView partial: 'GitLab Integration'
      @addSubView @switch


  link: ->

    kd.singletons.oauthController.redirectToOauthUrl { provider: 'gitlab' }


  unlink: ->

    me = whoami()
    me.unlinkOauth 'gitlab', (err) =>
      return showError err  if err

      me.unstore 'ext|profile|gitlab', (err, storage) ->
        return kd.warn err  if err

      new kd.NotificationView {
        title: 'Your GitLab integration is now disabled.'
      }

      @linked = no


  getLoaderView: ->

    new kd.LoaderView
      cssClass   : 'main-loader'
      showLoader : yes
      size       :
        width    : 25
        height   : 25

