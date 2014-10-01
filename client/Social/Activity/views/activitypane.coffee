class ActivityPane extends MessagePane

  constructor: (options, data) ->
    options.type        or= ''
    options.cssClass     ?= "activity-pane #{options.type}"
    options.wrapper      ?= yes
    options.lastToFirst  ?= no

    KDTabPaneView.call this, options, data

    @createChannelTitle()
    @createInputWidget()
    @bindInputEvents()
    @createContentViews()
    @createTabView()
    @createSearchInput()

    @once 'ChannelReady', @bound 'bindChannelEvents'
    KD.singletons.socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    @fakeMessageMap = {}

    if @getData().typeConstant in ['group', 'topic']
      @on 'LazyLoadThresholdReached', @bound 'lazyLoad'

  createContentViews: ->
    data = @getData()
    options = @getContentOptions()

    @mostLiked = @createMostLikedView options, data
    @mostRecent = @createMostRecentView options, data
    @searchResults = @createSearchResultsView options, data

  getContentOptions: ->
    o = @getOptions()

    lastToFirst   : o.lastToFirst
    channelId     : o.channelId
    wrapper       : o.wrapper
    itemClass     : o.itemClass
    typeConstant  : @getData().typeConstant

  createMostLikedView: (options, data) ->
    new ActivityContentPane options, data
      .on "NeedsMoreContent", =>
        from = null
        skip = @mostLiked.getLoadedCount()

        @fetch { from, skip, mostLiked:yes }, @createContentAppender 'mostLiked'

  createMostRecentView: (options, data) ->
    new ActivityContentPane options, data
      .on "NeedsMoreContent", =>
        from = @mostRecent.getContentFrom()
        skip = null

        @fetch { from, skip }, @createContentAppender 'mostRecent'

  createSearchResultsView: (options, data) ->
    new ActivitySearchResultsPane options, data
      .on "NeedsMoreContent", =>
        if @searchResults.currentPage?
          page = @searchResults.currentPage += 1

          @search @currentSearch, { page }

  getPaneData: ->
    [
      {
        name          : 'Most Liked'
        view          : @mostLiked
        closable      : no
        route         : '/Activity/Public/Liked'
      }
      {
        name          : 'Most Recent'
        view          : @mostRecent
        closable      : no
        shouldShow    : no
        route         : '/Activity/Public/Recent'
      }
      {
        name          : 'Search'
        view          : @searchResults
        closable      : no
        shouldShow    : no
        hiddenHandle  : yes
      }
    ]

  createTabView: ->
    @tabView = new KDTabView
      cssClass          : 'activity-tab-view'
      tabHandleClass    : ActivityTabHandle
      maxHandleWidth    : Infinity
      paneData          : @getPaneData()
    @tabView.tabHandleContainer.setClass 'filters'
    @tabView.on 'PaneDidShow', @bound 'handlePaneShown'


  handlePaneShown: (pane) ->

    switch pane
      when @mostLiked?.parent
        @setSearchedState no
        @select 'mostLiked', mostLiked: yes
      when @mostRecent?.parent
        @setSearchedState no
        @select 'mostRecent'
      when @searchResults?.parent
        @setSearchedState yes
        @activeContent = @searchResults


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
    @addSubView @channelTitleView
    @addSubView @input
    @addSubView @tabView

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

  search: (text, options) ->
    @searchResults.startSearch()

    KD.singletons.search
      .searchChannel text, @getData().id, options
      .then (results) =>
        @searchResults.setContent results
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
