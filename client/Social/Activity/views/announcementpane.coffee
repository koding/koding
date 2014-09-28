class AnnouncementPane extends ActivityPane

  constructor: (options, data) ->
    options.cssClass = "activity-pane announcement-pane #{options.type}"
    super options, data


  viewAppended: ->

    @addSubView @channelTitleView
    KD.singletons.mainView.ready =>
      @addSubView @input  if 'admin' in KD.config.roles
      @addSubView @tabView


  createContentViews: ->
    data = @getData()
    options = @getContentOptions()

    @mostRecent = @createMostRecentView options, data

    # TODO: enabling search results is OK, but the input needs a close box.

    # @searchResults = @createSearchResultsView options, data

  createInputWidget: ->
    super "Enter announcement here"

  createSearchInput: ->
    # TODO: remove this stub method when re-enabling announcement search.

  getPaneData: ->
    [
      {
        name          : 'Most Recent'
        view          : @mostRecent
        closable      : no
        hiddenHandle  : yes
        route         : '/Activity/Public/Recent'
      }
      # {
      #   name          : 'Search Tab'
      #   view          : @searchResults
      #   closable      : no
      #   shouldShow    : no
      #   hiddenHandle  : yes
      # }
    ]


