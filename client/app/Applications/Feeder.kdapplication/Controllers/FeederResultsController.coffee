class FeederResultsController extends KDViewController
  constructor:(options = {}, data)->
    options.view                or= new FeederTabView hideHandleCloseIcons : yes
    options.paneClass           or= FeederTabPaneView
    options.subItemClass        or= KDListItemView
    options.listControllerClass or= KDListViewController

    super options,data

    @panes = {}
    @listControllers = {}

    for name, filter of options.filters
      @createTab name,filter

  loadView:(mainView)->
    mainView.hideHandleContainer()
    mainView.showPaneByIndex 0
    # baad
    setTimeout ->
      mainView._windowDidResize()
    ,500

  openTab:(filter, callback)->
    tabView = @getView()
    pane = tabView.getPaneByName filter.name
    tabView.showPane pane
    callback? @listControllers[filter.name]

  createTab:(name, filter, callback)->
    {paneClass,subItemClass,listControllerClass,listCssClass} = @getOptions()
    tabView = @getView()

    @listControllers[name] = listController = new listControllerClass
      lazyLoadThreshold : .75
      viewOptions       :
        cssClass        : listCssClass
        subItemClass    : subItemClass
        type            : name

    listController.registerListener
      KDEventTypes  : 'LazyLoadThresholdReached'
      listener      : @
      callback      : =>
        @propagateEvent KDEventType : "LazyLoadThresholdReached"

    tabView.addPane @panes[name] = new paneClass
      name : name

    @panes[name].addSubView @panes[name].listHeader  = new CommonListHeader
      title : filter.optional_title or filter.title

    @panes[name].addSubView @panes[name].listWrapper = listController.getView()

    callback? listController
