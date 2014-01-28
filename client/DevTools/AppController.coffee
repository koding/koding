class DevToolsController extends AppController

  KD.registerAppClass this,
    name     : "DevTools"
    route    : "/DevTools"
    behavior : "application"

  constructor:(options = {}, data)->
    options.view    = new DevToolsMainView
    options.appInfo =
      name     : "DevTools"
      type     : "application"

    super options, data

  # FIXME facet, to make it work I had to call notifyWindowResizeListeners here
  handleQuery:->
    {workspace} = @getView()
    workspace.ready ->
      KD.getSingleton("windowController").notifyWindowResizeListeners()