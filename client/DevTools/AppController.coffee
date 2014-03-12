class DevToolsController extends AppController

  name    = "DevTools"
  version = "0.1"
  route   = "/:name?/#{name}"

  KD.registerAppClass this, {
    name, version, behavior: "application", route,
    menu          : [
      { title     : "Create a new App",    eventName : "create" }
      { type      : "separator" }
      { title     : "Save",                eventName : "save" }
      { title     : "Save All",            eventName : "saveAll" }
      { type      : "separator" }
      { title     : "Publish to AppStore", eventName : "publis" }
      { title     : "customViewToggleLiveReload" }
      { type      : "separator" }
      { title     : "customViewToggleFullscreen" }
      { type      : "separator" }
      { title     : "Exit",                eventName : "exit" }
    ]
  }

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