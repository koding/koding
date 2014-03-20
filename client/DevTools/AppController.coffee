class DevToolsController extends AppController

  name    = "DevTools"
  version = "0.1"
  route   = "/:name?/#{name}"

  KD.registerAppClass this, {
    name, version, behavior: "application", route,
    menu          :
      items       : [
        { title     : "Create a new App",    eventName : "create" }
        { type      : "separator" }
        { title     : "Save",                eventName : "save" }
        { title     : "Save All",            eventName : "saveAll" }
        { title     : "Close All",           eventName : "closeAll" }
        { type      : "separator" }
        { title     : "Compile on server",   eventName : "compile" }
        { title     : "Publish for Testing", eventName : "publishTest" }
        { title     : "Publish to AppStore", eventName : "publish" }
        { title     : "customViewToggleLiveReload" }
        { type      : "separator" }
        { title     : "customViewToggleFullscreen" }
        { type      : "separator" }
        { title     : "Exit",                eventName : "exit" }
      ]
      hiddenOnStart : yes
  }

  constructor:(options = {}, data)->
    options.view    = new DevToolsMainView
    options.appInfo =
      name     : "DevTools"
      type     : "application"

    super options, data

  # FIXME facet, to make it work I had to call notifyWindowResizeListeners here
  handleQuery:->
    {workspace, _currentMode} = @getView()

    workspace.ready ->
      wc = KD.getSingleton("windowController")
      wc.notifyWindowResizeListeners()
      wc.notifyWindowResizeListeners()

      unless _currentMode is 'home'
        KD.singletons.mainView.appSettingsMenuButton.show()