class ActivityPane extends MessagePane

  constructor: (options, data) ->
    options.type    or= ''
    options.cssClass  = "activity-pane #{options.type}"
    options.wrapper     ?= yes
    options.lastToFirst ?= no

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

    @mostLiked = new ActivityMostLikedContentPane options, data
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
        console.log 'we need to implement pagination for search results'

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
        @select 'mostLiked',
          mostLiked: yes
          forceLoad: yes
      when @mostRecent.parent
        @select 'mostRecent'

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

  createSearchInput: ->
    @searchInput = new SearchInputView

    @tabView.tabHandleContainer.addSubView @searchInput

    @searchInput.on 'SearchRequested', (userText) =>
      @tabView.showPane @tabView.panes.last
      @searchResults.startSearch()
      KD.singletons.search
        .searchChannel userText, @getData().id
        .then (results) =>
          @searchResults.finishSearch()
          @searchResults.setContent results
        .catch KD.showError
