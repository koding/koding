class ActivityPane extends MessagePane

  constructor: (options, data) ->
    options.type        or= ''
    options.cssClass      = "activity-pane #{options.type}"
    options.wrapper      ?= yes
    options.lastToFirst  ?= no

    KDTabPaneView.call this, options, data

    @createChannelTitle()
    @createInputWidget()
    @bindInputEvents()
    @createTabView()
    @createSearchInput()

    @once 'ChannelReady', @bound 'bindChannelEvents'
    KD.singletons.socialapi.onChannelReady data, @lazyBound 'emit', 'ChannelReady'

    @fakeMessageMap = {}

    if @getData().typeConstant in ['group', 'topic']
      @on 'LazyLoadThresholdReached', @bound 'lazyLoad'

  createTabView: ->
    o = @getOptions()
    data = @getData()

    options =
      lastToFirst   : o.lastToFirst
      channelId     : o.channelId
      wrapper       : o.wrapper
      itemClass     : o.itemClass
      typeConstant  : data.typeConstant

    @mostLiked = new ActivityContentPane options, data
      .on "NeedsMoreContent", =>
        from = null
        skip = @mostLiked.getLoadedCount()

        @fetch { from, skip }, @createContentAppender 'mostLiked'

    @mostRecent = new ActivityContentPane options, data
      .on "NeedsMoreContent", =>
        from = @mostRecent.getContentFrom()
        skip = null

        @fetch { from, skip }, @createContentAppender 'mostRecent'

    @searchResults = new ActivitySearchResultsPane options, data
      .on "NeedsMoreContent", =>
        if @searchResults.currentPage?
          page = @searchResults.currentPage += 1

          @search @currentSearch, { page }

    @tabView = new KDTabView
      cssClass          : 'activity-tab-view'
      tabHandleClass    : ActivityTabHandle
      maxHandleWidth    : Infinity
      paneData          : [
        {
          name          : 'Most Liked'
          view          : @mostLiked
          closable      : no
          shouldShow    : yes
        }
        {
          name          : 'Most Recent'
          view          : @mostRecent
          closable      : no
          shouldShow    : no
        }
        {
          name          : 'Search Tab'
          view          : @searchResults
          closable      : no
          shouldShow    : no
          hiddenHandle  : yes
        }
      ]
    @tabView.tabHandleContainer.setClass 'filters'
    @tabView.on "PaneDidShow", (pane) => switch pane
      when @mostLiked.parent
        @select 'mostLiked', mostLiked: yes
      when @mostRecent.parent
        @select 'mostRecent'
      when @searchResults.parent
        @activeContent = @searchResults

  select: (contentName, options = {}) ->
    content = @[contentName]

    @searchInput.clear()
    @searchResults.clear()

    unless content.isLoaded
      @fetch options, @createContentSetter contentName

  lazyLoad: -> @activeContent?.loadMore()

  putMessage: (message, index = 0) ->
    @tabView.showPane @tabView.getPaneByName 'Most Recent'
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

  removeMessage: (message) ->
    for contentPane in [@mostLiked, @mostRecent, @searchResults]
      contentPane.removeMessage message

  search: (text, options) ->
    @searchResults.startSearch()

    KD.singletons.search
      .searchChannel text, @getData().id, options
      .then (results) =>
        @searchResults.appendContent results
      .catch KD.showError

  createSearchInput: ->
    @searchInput = new SearchInputView
      placeholder : 'Search channel'

    @tabView.tabHandleContainer.addSubView @searchInput

    searchIcon = new KDCustomHTMLView
      tagName  : 'cite'
      cssClass : 'search-icon'

    @tabView.tabHandleContainer.addSubView searchIcon

    @searchInput.on 'SearchRequested', (text) =>
      @tabView.showPane @tabView.panes.last
      @searchResults.clear()
      @search text
      @currentSearch = text
