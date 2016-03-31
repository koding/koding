kd          = require 'kd'
MainTabView = require './maintabview'


module.exports = class MainView extends kd.View

  constructor: (options = {}, data) ->

    options.domId    = 'kdmaincontainer'
    options.cssClass = if kd.isLoggedInOnLoad then 'with-sidebar' else ''

    super options, data


  viewAppended: ->

    @createMainTabView()

    @emit 'ready'


  createMainTabView: ->

    @mainTabView = new MainTabView
      domId               : 'main-tab-view'
      listenToFinder      : yes
      delegate            : this
      slidingPanes        : no
      hideHandleContainer : yes


    @mainTabView.on 'PaneDidShow', (pane) => @emit 'MainTabPaneShown', pane


    @mainTabView.on 'AllPanesClosed', ->
      kd.singletons.router.handleRoute '/Activity'

    @addSubView @mainTabView
