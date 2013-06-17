class KodingAppController extends KDViewController

  constructor: (options = {}, data)->

    options.view = new KDView

    super options, data

  handleQuery: (query) ->
    @getView().emit "HandleQuery", query

  openFile: (file) ->
    @getView().emit "OpenFile", file