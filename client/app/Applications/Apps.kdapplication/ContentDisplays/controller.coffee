class ContentDisplayControllerApps extends KDViewController
  constructor:(options = {}, data)->
    
    options.view or= mainView = new KDView cssClass : 'apps content-display'

    super options, data

  loadView:(mainView)->

    app = @getData()

    mainView.addSubView subHeader = new KDCustomHTMLView tagName : "h2", cssClass : 'sub-header'
    subHeader.addSubView backLink = new KDCustomHTMLView
      tagName     : "a"
      partial     : "<span>&laquo;</span> Back"
      attributes  :
        href      : "#"
      click       : ->
        contentDisplayController.propagateEvent KDEventType : "ContentDisplayWantsToBeHidden",mainView

    contentDisplayController = @getSingleton "contentDisplayController"

    # mainView.addSubView wrapperView = new AppViewMainPanel {}, app

    mainView.addSubView appView = new AppView
      cssClass : "profilearea clearfix"
      delegate : mainView
    , app

    # @innerNav = new SingleAppNavigation
    # @tabs     = new KDTabView
    #   cssClass             : "app-info-tabs"
    #   hideHandleCloseIcons : yes
    #   hideHandleContainer  : yes
    # @createTabs()
    # mainView.addSubView appSplit = new ContentPageSplitBelowHeader
    #   views     : [@innerNav,@tabs]
    #   sizes     : [139,null]
    #   minimums  : [10,null]
    #   resizable : no

    # appSplit._windowDidResize()

  createTabs:()->
    app = @getData()
    @tabs.addPane infoTab = new KDTabPaneView
      name : 'appinfo'
    @tabs.addPane screenshotsTab = new KDTabPaneView
      name : 'screenshots'

    infoTab.addSubView new CommonListHeader
      title : "Application Info"
    infoTab.addSubView new AppInfoView
      cssClass : "info-wrapper"
    , app

    screenshotsListController = new KDListViewController
      view            : new KDListView
        subItemClass  : AppScreenshotsListItem
    ,
      items           : app.screenshots

    screenshotsTab.addSubView screenshotsListController.getView()
    # screenshotsListController.getView().addSubView new CommonListHeader
    #   title : "Screenshots"
    # , null, yes

    @tabs.showPane infoTab

    @innerNav.registerListener
      KDEventTypes  : "CommonInnerNavigationListItemReceivedClick"
      listener      : @
      callback      : (pubInst,event)=>
        @tabs.showPaneByName event.type
