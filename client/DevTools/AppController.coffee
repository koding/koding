class DevToolsController extends AppController

  name    = "DevTools"
  version = "0.1"
  route   = "/#{name}"

  KD.registerAppClass this, {name, version, behavior: "application", route}

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