class FeedController extends KDViewController

  USEDFEEDS = []

  constructor:(options={})->

    options.autoPopulate   ?= no
    options.useHeaderNav   ?= no
    options.filter        or= {}
    options.sort          or= {}
    options.limitPerPage  or= 10
    options.dataType      or= null
    options.onboarding    or= null
    options.domId         or= ''
    options.delegate       ?= null

    resultsController = options.resultsController or FeederResultsController
    @resultsController = new resultsController
      itemClass           : options.itemClass
      filters             : options.filter
      listControllerClass : options.listControllerClass
      listCssClass        : options.listCssClass or ""
      delegate            : @
      onboarding          : options.onboarding
      creator             : options.creator

    unless options.useHeaderNav
      facetsController    = options.facetsController or FeederFacetsController
      @facetsController   = new facetsController
        filters   : options.filter
        sorts     : options.sort
        help      : options.help
        delegate  : @

      options.view or= new FeederSplitView
        domId   : options.domId
        views   : [
          @facetsController.getView()
          @resultsController.getView()
        ]
    else
      facetsController    = options.facetsController or FeederHeaderFacetsController
      @facetsController   = new facetsController
        filters   : options.filter
        sorts     : options.sort
        help      : options.help
        delegate  : @

      view = (options.view or= new FeederSingleView)

      view.on "viewAppended", =>
        view.addSubView @resultsController.getView()
        view.addSubView @facetsController.getView()

    super options, null

    options             = @getOptions()
    @filters            = {}
    @sorts              = {}
    @defaultQuery       = options.defaultQuery ? {}

    {delegate} = options
    if delegate then delegate.on 'LazyLoadThresholdReached', @bound 'loadFeed'
    else @resultsController.on   'LazyLoadThresholdReached', @bound 'loadFeed'

    @defineFilter name, filter for own name, filter of options.filter
    @defineSort name, sort for own name, sort of options.sort
    @getNewFeedItems() if options.dynamicDataType?

    @on "FilterLoaded", ->
      KD.getSingleton("windowController").notifyWindowResizeListeners()

  highlightFacets:->
    filterName  = @selection.name
    sortName    = @selection.activeSort or @defaultSort.name
    @facetsController.highlight filterName, sortName

  handleQuery:({filter, sort}, options = {})->
    if filter
      unless @filters[filter]?
        filter = (Object.keys @filters).first
      @selectFilter filter, no

    if sort
      unless @sorts[sort]?
        sort = (Object.keys @sorts).first
      @changeActiveSort sort, no

    @highlightFacets()

    if options.force
    then @reload()
    else @loadFeed()

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

  selectFilter:(name, loadFeed=yes)->
    @selection = @filters[name]
    @resultsController.openTab @filters[name]
    if @resultsController.listControllers[name].itemsOrdered.length is 0
      @loadFeed() if loadFeed
    @emit 'FilterChanged', name

  changeActiveSort:(name, loadFeed=yes)->
    @selection.activeSort = name
    @resultsController.listControllers[@selection.name].removeAllItems()
    @loadFeed() if loadFeed

  getFeedSelector:->
    # log @filters
    {}

  getFeedOptions:->
    options = sort : {}

    filter  = @selection
    sort    = @sorts[@selection.activeSort] or @defaultSort

    options.sort[sort.name.split('|')[0]] = sort.direction
    options.limit = @getOptions().limitPerPage
    options.skip  = @resultsController.listControllers[filter.name].itemsOrdered.length
    options

  emitLoadStarted:(filter)->
    listController = @resultsController.listControllers[filter.name]
    listController.showLazyLoader no
    return listController

  emitLoadCompleted:(filter)->
    listController = @resultsController.listControllers[filter.name]
    listController.hideLazyLoader()
    return listController

  emitCountChanged:(count, filter)->
    @resultsController.getDelegate().emit "FeederListViewItemCountChanged", count, filter

  # this is a temporary solution for a bug that
  # bongo returns correct result set in a wrong order
  sortByKey : (array, key) ->
    array.sort (first, second) ->
      firstVar  = JsPath.getAt first,  key
      secondVar = JsPath.getAt second, key
      #quick sort-ware
      if (firstVar < secondVar) then return 1
      else if (firstVar > secondVar) then return -1
      else return 0

  reload:->
    {selection, defaultSort} = this
    @changeActiveSort selection.activeSort or defaultSort.title

  loadFeed:(filter = @selection)=>

    options    = @getFeedOptions()
    selector   = @getFeedSelector()
    {itemClass, feedId}  = @getOptions()
    feedId = "" unless feedId
    {groupsController} = KD.singletons

    if KD.config.entryPoint?.type is 'group'
    then group = KD.config.entryPoint.slug
    else group = 'koding'

    groupsController.changeGroup group, =>

      currentGroup = group
      feedId = "#{currentGroup}-#{feedId}"

      kallback = (err, items, rest...)=>
        listController = @emitLoadCompleted filter
        @emit "FilterLoaded"
        {limit}      = options
        {scrollView} = listController
        if items?.length > 0
          unless err
            items = @sortByKey(items, filter.activeSort) if filter.activeSort
            listController.instantiateListItems items
            @emitCountChanged listController.itemsOrdered.length, filter.name
          else
            warn err
        else unless err
          filter.dataEnd? this, rest...
        else
          filter.dataError? this, err

      @emitLoadStarted filter
      if options.skip isnt 0 and options.skip < options.limit # Dont load forever
        @emitLoadCompleted filter
        @emit "FilterLoaded"
      else unless feedId in USEDFEEDS
        USEDFEEDS.push feedId
        if KD.prefetchedFeeds and prefetchedItems = KD.prefetchedFeeds[feedId]
          kallback null, (KD.remote.revive item for item in prefetchedItems)
        else
          @loadFeed filter
      else
        filter.dataSource selector, options, kallback
