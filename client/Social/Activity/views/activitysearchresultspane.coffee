class ActivitySearchResultsPane extends ActivityContentPane

  startSearch: ->
    @listController.showLazyLoader()

  finishSearch: -> # ignore

  clear: ->
    @listController.removeAllItems()
