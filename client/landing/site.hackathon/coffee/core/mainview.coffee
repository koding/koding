CustomLinkView = require './customlinkview'
MainTabView    = require './maintabview'

module.exports = class MainView extends KDView

  constructor: (options = {}, data)->

    options.domId    = 'kdmaincontainer'
    options.cssClass = if KD.isLoggedInOnLoad then 'with-sidebar' else ''

    super options, data

    @notifications = []


  viewAppended: ->

    {mainController} = KD.singletons

    @createPanelWrapper()
    @createMainTabView()

    @emit 'ready'


  createPanelWrapper:->

    @addSubView @panelWrapper = new KDView
      tagName  : 'section'
      domId    : 'main-panel-wrapper'

    @panelWrapper.addSubView new KDCustomHTMLView
      tagName  : 'cite'
      domId    : 'sidebar-toggle'
      click    : => @toggleClass 'collapsed'


  createMainTabView:->

    @mainTabView = new MainTabView
      domId               : 'main-tab-view'
      listenToFinder      : yes
      delegate            : this
      slidingPanes        : no
      hideHandleContainer : yes


    @mainTabView.on 'PaneDidShow', (pane) => @emit 'MainTabPaneShown', pane

    @mainTabView.on "AllPanesClosed", -> KD.singletons.router.clear()

    @panelWrapper.addSubView @mainTabView
