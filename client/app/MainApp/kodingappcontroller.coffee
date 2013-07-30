class KodingAppController extends KDViewController

  constructor: (options = {}, data)->

    options.view = view = new KDView

    super options, data

    view.on 'ready', => @emit 'ready'

  handleQuery: (query) ->
    @ready => @getView().emit "QueryPassedFromRouter", query

  openFile: (file) ->
    @ready => @getView().emit "FileNeedsToBeOpened", file



