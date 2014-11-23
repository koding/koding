class ActivityPane extends MessagePane

  PANE_OPTIONS = [
      name          : 'Most Liked'
      closable      : no
      route         : '/Activity/Public/Liked'
    ,
      name          : 'Most Recent'
      closable      : no
      shouldShow    : no
      route         : '/Activity/Public/Recent'
    ,
      name          : 'Search'
      closable      : no
      shouldShow    : no
      hiddenHandle  : yes
  ]


  constructor: (options, data) ->
    options.type        or= ''
    options.cssClass      = KD.utils.curry "activity-pane #{options.type}", options.cssClass
    options.wrapper      ?= yes
    options.scrollView   ?= yes
    options.lastToFirst  ?= no

    KDTabPaneView.call this, options, data

    @createChannelTitle()
    @createInputWidget()
    @createScrollView()
    @bindLazyLoader()
    @bindInputEvents()
    @createTabView()
    @createWidgetsBar()
    @createContentViews()
    @createSearchInput()

    @once 'ChannelReady', @bound 'bindChannelEvents'
    KD.singletons.socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    @fakeMessageMap = {}


  getActiveContentOptions: ->

    panes =
      '/Activity/Public/Liked'  : { name: 'mostLiked',  pane: @mostLiked }
      '/Activity/Public/Recent' : { name: 'mostRecent', pane: @mostRecent }

    path = KD.singletons.router.getCurrentPath()

    return panes[path]


  refreshContent: ->

    return  if @fetching

    options = @getActiveContentOptions()

    @refreshContentPane options


  refreshContentPane: (options) ->

    { pane, name } = options
    { listController } = pane

    listController.showLazyLoader no

    fetchOptions = {}
    fetchOptions[name] = yes

    @fetch fetchOptions, @createContentSetter name


  bindLazyLoader: ->

    @scrollView.wrapper.on 'LazyLoadThresholdReached', =>
      @activeContent?.emit 'NeedsMoreContent'


  createWidgetsBar: ->

    @widgetsBar = new ActivityWidgetsBar


  createContentViews: ->

    data       = @getData()
    getOptions = (i) => $.extend PANE_OPTIONS[i], @getContentOptions()

    @tabView.addPane @mostLiked     = @createMostLikedView     getOptions(0), data
    @tabView.addPane @mostRecent    = @createMostRecentView    getOptions(1), data
    @tabView.addPane @searchResults = @createSearchResultsView getOptions(2), data


  getContentOptions: ->
    o = @getOptions()

    lastToFirst   : o.lastToFirst
    channelId     : o.channelId
    wrapper       : o.wrapper
    itemClass     : o.itemClass
    typeConstant  : @getData().typeConstant


  createMostLikedView: (options, data) ->
    pane = new ActivityContentPane options, data
      .on 'NeedsMoreContent', =>
        from = null
        skip = @mostLiked.getLoadedCount()

        pane.listController.showLazyLoader()

        @fetch { from, skip, mostLiked:yes }, @createContentAppender 'mostLiked'

      .on 'PaneDidShow', =>
        @setSearchedState no
        @select 'mostLiked', mostLiked: yes


  createMostRecentView: (options, data) ->
    pane = new ActivityContentPane options, data
      .on 'NeedsMoreContent', =>

        @lazyLoad pane.listController, @createContentAppender 'mostRecent'

      .on 'PaneDidShow', =>
        @setSearchedState no
        @select 'mostRecent'


  createSearchResultsView: (options, data) ->
    pane = new ActivitySearchResultsPane options, data
      .on "NeedsMoreContent", =>
        if @searchResults.currentPage?
          page = @searchResults.currentPage += 1

          pane.listController.showLazyLoader()

          @search @currentSearch, { page, dontClear: yes }

      .on 'PaneDidShow', =>
        @setSearchedState yes
        @activeContent = @searchResults


  createTabView: ->

    @tabView = new KDTabView
      cssClass          : 'activity-tab-view'
      tabHandleClass    : ActivityTabHandle
      maxHandleWidth    : Infinity

    @tabView.unsetClass 'kdscrollview'
    @tabView.tabHandleContainer.setClass 'filters'


  open: (name, query) ->

    @tabView.showPane @tabView.getPaneByName name

    if name is 'Search' and not query
      KD.singletons.router.handleRoute '/Activity/Public/Recent'
      return

    return  unless query

    @searchInput.setValue query
    @searchInput.setFocus()
    @search query
    @currentSearch = query


  clearSearch: ->
    @searchInput?.clear()
    @searchResults?.clear()

  select: (contentName, options = {}) ->
    content = @[contentName]

    @clearSearch()

    unless content.isLoaded
      @fetch options, @createContentSetter contentName

  putMessage: (message, index = 0) ->

    {router}       = KD.singletons
    currentPath    = router.getCurrentPath()
    mostRecentPath = '/Activity/Public/Recent'

    router.handleRoute mostRecentPath  unless currentPath is mostRecentPath

    @mostRecent.listController.addItem message, index


  contentMethod = (method) -> (contentName) -> (err, content) =>

    return KD.showError err  if err?

    @activeContent = @[contentName]
    @activeContent[method] content
    @fetching = no


  createContentSetter: contentMethod 'setContent'

  createContentAppender: contentMethod 'appendContent'

  viewAppended: ->

    @addSubView @scrollView

    {wrapper} = @scrollView

    wrapper.addSubView @channelTitleView
    wrapper.addSubView @input
    wrapper.addSubView @tabView
    wrapper.addSubView @widgetsBar

  removeFakeMessage: (identifier) ->
    @mostRecent.removeItem @fakeMessageMap[identifier]

  appendMessage: (message, index) -> @mostRecent.addItem message, index

  prependMessage: (message, index) ->
    KD.getMessageOwner message, (err, owner) =>
      return error err  if err
      return if KD.filterTrollActivity owner
      @mostRecent.addItem message, index

  removeMessage: (message) ->
    for contentPane in [@mostLiked, @mostRecent, @searchResults]
      contentPane.removeMessage message

  search: (text, options = {}) ->
    @searchResults.startSearch()

    @searchResults.clear()  unless options.dontClear

    KD.singletons.search
      .searchChannel text, @getData().id, options
      .then (results) =>
        @searchResults.appendContent results
      .catch KD.showError


  setSearchedState: (state)->

    @isSearched = state
    {tabHandleContainer} = @tabView

    if state
    then tabHandleContainer.setClass 'search-active'
    else tabHandleContainer.unsetClass 'search-active'

    return state


  createSearchInput: ->

    {router} = KD.singletons

    @searchInput = new SearchInputView
      placeholder : 'Search...'

    @tabView.tabHandleContainer.addSubView @searchInput

    searchIcon = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'search-icon'
      click    : =>
        return  unless @isSearched
        router.handleRoute '/Activity/Public/Recent'

    @tabView.tabHandleContainer.addSubView searchIcon
