class AnnouncementPane extends ActivityPane

  constructor: (options, data) ->
    options.cssClass = "activity-pane announcement-pane #{options.type}"
    super options, data

  viewAppended: ->
    super()

    # TODO: this will be a false negative if the roles are not loaded yet.
    #       this should be fixed upstream by making sure the roles are
    #       available when the page is loaded. C.T.
    @input.hide()  unless 'admin' in KD.config.roles

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


