class ActivitySearchResultsPane extends ActivityContentPane

  constructor: (options = {}, data) ->
    options.resultsPerPage ?= 20

    super options, data

  startSearch: ->
    @listController.showLazyLoader()

  finishSearch: -> # ignore

  clear: ->
    @listController.removeAllItems()
    @currentPage = 0

  appendContent: (content) ->
    super content
    @currentPage = null  if content.length < @getOption 'resultsPerPage'
