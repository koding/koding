class FeedController extends KDViewController
  constructor:(options={})->
    facetsController = options.facetsController or FeederFacetsController
    @facetsController   = new facetsController
      filters   : options.filter
      sorts     : options.sort
      help      : options.help
      delegate  : @

    resultsController = options.resultsController or FeederResultsController
    @resultsController  = new resultsController
      subItemClass  : options.subItemClass
      filters       : options.filter
      listCssClass  : options.listCssClass or ""
      delegate      : @

    options.view or= new FeederSplitView
      views   : [
        @facetsController.getView()
        @resultsController.getView()
      ]

    options.autoPopulate  or= yes
    options.filter        or= {}
    options.sort          or= {}
    options.limitPerPage  or= 10

    options.dataType      or= null

    super options, null

    options             = @getOptions()
    @filters            = {}
    @sorts              = {}

    @facetsController.registerListener
      KDEventTypes  : 'FilterDidChange'
      listener      : @
      callback      : (pubInst, item)=>
        @selectFilter item.type

    @facetsController.registerListener
      KDEventTypes  : 'SortDidChange'
      listener      : @
      callback      : (pubInst, item)=>
        @changeActiveSort item.type

    @resultsController.getView().on 'PaneDidShow', (pane)=>
      filterName  = @selection.name
      sortName    = @selection.activeSort or @defaultSort.name
      @facetsController.highlight filterName, sortName

    @resultsController.registerListener
      KDEventTypes  : 'LazyLoadThresholdReached'
      listener      : @
      callback      : =>
        @loadFeed()

    @defineFilter name, filter for own name, filter of options.filter
    @defineSort name, sort for own name, sort of options.sort
    @getNewFeedItems() if options.dynamicDataType?

  getNewFeedItems:()->
    {dynamicDataType} = @getOptions()
    dynamicDataType.on 'feed.new', (items) =>
      @resultsCOntroller.emit 'NewFeedItemsFromFeeder', items

  defineFilter:(name, filter)->
    filter.name     = name
    @filters[name]  = filter
    if filter.isDefault or not @selection?
      @selection    = filter

  defineSort:(name, sort)->
    sort.name     = name
    @sorts[name]  = sort
    if sort.isDefault or not @defaultSort?
      @defaultSort = sort

  loadView:(mainView)->
    @loadFeed() if @getOptions().autoPopulate
    mainView._windowDidResize()

  selectFilter:(name)->
    @selection = @filters[name]
    @resultsController.openTab @filters[name]
    if @resultsController.listControllers[name].itemsOrdered.length is 0
      @loadFeed()

  changeActiveSort:(name)->
    @selection.activeSort = name
    @resultsController.listControllers[@selection.name].removeAllItems()
    @loadFeed()

  getFeedSelector:->
    # console.log @filters
    {}

  getFeedOptions:->
    options = sort : {}

    filter  = @selection
    sort    = @sorts[@selection.activeSort] or @defaultSort

    options.sort[sort.name] = sort.direction
    options.limit = @getOptions().limitPerPage
    options.skip  = @resultsController.listControllers[filter.name].itemsOrdered.length
    options

  emitLoadStarted:(filter)=>
    listController = @resultsController.listControllers[filter.name]
    listController.showLazyLoader no
    return listController

  emitLoadCompleted:(filter)=>
    listController = @resultsController.listControllers[filter.name]
    listController.hideLazyLoader()
    return listController

  loadFeed:(filter = @selection)->

    options          = @getFeedOptions()
    selector         = @getFeedSelector()
    windowController = @getSingleton('windowController')
    subItemClass     = @getOptions().subItemClass

    @emitLoadStarted filter
    if options.skip isnt 0 and options.skip < options.limit # Dont load forever
      @emitLoadCompleted filter
    else
      filter.dataSource selector, options, (err, items)=>
        listController = @emitLoadCompleted filter
        unless err
          listController.instantiateListItems items
          windowController.emit "FeederListViewItemCountChanged", listController.itemsOrdered.length, subItemClass, filter.name
          if items.length is options.limit and listController.scrollView.getScrollHeight() <= listController.scrollView.getHeight()
            @loadFeed filter
        else
          warn err
