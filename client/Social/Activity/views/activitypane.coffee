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
    options.cssClass     ?= "activity-pane #{options.type}"
    options.wrapper      ?= yes
    options.scrollView   ?= yes
    options.lastToFirst  ?= no

    KDTabPaneView.call this, options, data

    @createChannelTitle()
    @createInputWidget()
    @bindInputEvents()
    @createTabView()
    @createContentViews()
    @createSearchInput()

    @once 'ChannelReady', @bound 'bindChannelEvents'
    KD.singletons.socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    @fakeMessageMap = {}

    if @getData().typeConstant in ['group', 'topic']
      @on 'LazyLoadThresholdReached', @bound 'lazyLoad'


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
      .on "NeedsMoreContent", =>
        from = null
        skip = @mostLiked.getLoadedCount()

        pane.listController.showLazyLoader()

        @fetch { from, skip, mostLiked:yes }, @createContentAppender 'mostLiked'

      .on 'PaneDidShow', =>
        @setSearchedState no
        @select 'mostLiked', mostLiked: yes


  createMostRecentView: (options, data) ->
    pane = new ActivityContentPane options, data
      .on "NeedsMoreContent", =>
        from = @mostRecent.getContentFrom()
        skip = null

        pane.listController.showLazyLoader()

        @fetch { from, skip }, @createContentAppender 'mostRecent'

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

  lazyLoad: -> @activeContent?.loadMore()

  putMessage: (message, index = 0) ->
    {router} = KD.singletons
    router.handleRoute '/Activity/Public/Recent'
    @mostRecent.listController.addItem message, index

  contentMethod = (method) -> (contentName) -> (err, content) =>
    return KD.showError err  if err?

    @activeContent = @[contentName]
    @activeContent[method] content

  createContentSetter: contentMethod 'setContent'

  createContentAppender: contentMethod 'appendContent'

  viewAppended: ->

    @addSubView @scrollView = new KDCustomScrollView
      cssClass          : 'message-pane-scroller'
      lazyLoadThreshold : 100

    {wrapper} = @scrollView

    wrapper.addSubView @channelTitleView
    wrapper.addSubView @input
    wrapper.addSubView @tabView

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
