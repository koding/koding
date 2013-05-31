class FeedController extends KDViewController
  constructor:(options={})->


    options.autoPopulate   ?= no
    options.useHeaderNav   ?= no
    options.filter        or= {}
    options.sort          or= {}
    options.limitPerPage  or= 10
    options.dataType      or= null
    options.onboarding    or= null
    options.domId         or= ''

    resultsController = options.resultsController or FeederResultsController
    @resultsController  = new resultsController
      itemClass     : options.itemClass
      filters       : options.filter
      listCssClass  : options.listCssClass or ""
      delegate      : @
      onboarding    : options.onboarding

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

    @resultsController.on 'LazyLoadThresholdReached', => @loadFeed()

    @defineFilter name, filter for own name, filter of options.filter
    @defineSort name, sort for own name, sort of options.sort
    @getNewFeedItems() if options.dynamicDataType?

# TODO: commented out by C.T.  Is this used anywhere?  I think not, looks botched: resultsCOntroller
#  getNewFeedItems:()->
#    {dynamicDataType} = @getOptions()
#    dynamicDataType.on 'feed.new', (items) =>
#      @resultsCOntroller.emit 'NewFeedItemsFromFeeder', items

  highlightFacets:->
    filterName  = @selection.name
    sortName    = @selection.activeSort or @defaultSort.name
    @facetsController.highlight filterName, sortName

  handleQuery:({filter, sort})->
    @selectFilter filter, no      if filter?
    @changeActiveSort sort, no    if sort?
    @highlightFacets()
    @loadFeed()
    # console.log 'handle query is called on feed controller', @, arguments

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
    @showNoItemFound listController, filter
    return listController

  emitLoadCompleted:(filter)->
    listController = @resultsController.listControllers[filter.name]
    listController.hideLazyLoader()
    return listController

  emitCountChanged:(count, filter)->
    @resultsController.getDelegate().emit "FeederListViewItemCountChanged", count, filter

  showNoItemFound:(controller, filter)->
    {noItemFoundText} = filter
    if @noItemFound? then @noItemFound.destroy()
    controller.scrollView.addSubView @noItemFound = new KDCustomHTMLView
      cssClass : "lazy-loader"
      partial  : noItemFoundText or @getOptions().noItemFoundText or "There is no activity."
    @noItemFound.hide()

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
    itemClass  = @getOptions().itemClass

    @emitLoadStarted filter
    if options.skip isnt 0 and options.skip < options.limit # Dont load forever
      @emitLoadCompleted filter
    else
      filter.dataSource selector, options, (err, items, rest...)=>
        listController = @emitLoadCompleted filter
        if items?
          unless err
            if items.length is 0 and listController.getItemCount() is 0
              @noItemFound.show()
            items = @sortByKey(items, filter.activeSort) if filter.activeSort
            listController.instantiateListItems items
            @emitCountChanged listController.itemsOrdered.length, filter.name
            if items.length is options.limit and listController.scrollView.getScrollHeight() <= listController.scrollView.getHeight()
              @loadFeed filter
          else
            warn err
        else unless err
          if listController.getItemCount() is 0
            @noItemFound.show()
          filter.dataEnd? @, rest...
        else
          filter.dataError? @, err
