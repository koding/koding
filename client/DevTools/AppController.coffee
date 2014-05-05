class DevToolsController extends AppController

  KD.registerAppClass this,
    name            : 'DevTools'
    version         : '0.1'
    route           : '/:name?/DevTools'
    behavior        : 'application'
    preCondition    :
      condition     : (options, cb)-> cb KD.isLoggedIn()
      failure       : (options, cb)->
        KD.singletons.appManager.open 'DevTools', conditionPassed : yes
        KD.showEnforceLoginModal()
    menu            :
      hiddenOnStart : yes
      items         : [
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

  openFile:(file, callback)->

    app = KodingAppsController.getAppInfoFromPath file.path
    unless app then return new KDNotificationView
      title : "Not a Koding App directory"

    KD.singletons.router.handleRoute '/DevTools'

    view = @getView()
    view.ready =>

      {JSEditor, CSSEditor} = view.workspace.activePanel.panesByName
      JSEditor.loadFile  "#{app.fullPath}/index.coffee"
      CSSEditor.loadFile "#{app.fullPath}/resources/style.css"

      view.switchMode 'develop'