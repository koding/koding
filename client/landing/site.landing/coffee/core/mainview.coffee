TopNavigation  = require './topnavigation'
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

    @createHeader()

    @createPanelWrapper()
    @createMainTabView()

    @emit 'ready'


  createHeader:->

    @addSubView @mobileMenu = new TopNavigation
      cssClass     : 'mobile-menu'

    @addSubView @header = new KDView
      tagName  : 'header'
      domId    : 'main-header'

    @header.addSubView new TopNavigation

    @header.addSubView @hamburgerMenu = new KDButtonView
      cssClass  : 'hamburger-menu'
      iconOnly  : yes
      callback  : =>
        @hamburgerMenu.toggleClass 'active'
        @mobileMenu.toggleClass 'active'

        @once 'click', =>
          @hamburgerMenu.toggleClass 'active'
          @mobileMenu.toggleClass 'active'

    @header.addSubView @logo = new KDCustomHTMLView
      tagName   : 'a'
      domId     : 'koding-logo'
      partial   : '<cite></cite>'
      click     : (event) =>
        KD.utils.stopDOMEvent event
        KD.singletons.router.handleRoute '/'


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


    @mainTabView.on "AllPanesClosed", ->
      KD.getSingleton('router').handleRoute "/Activity"

    @panelWrapper.addSubView @mainTabView
