class DevToolsController extends AppController

  APPNAME = "DevTools"
  VERSION = "0.1"

  KD.registerAppClass this,
    name              : APPNAME
    version           : VERSION
    route             : '/:name?/DevTools'
    behavior          : 'application'
    preCondition      :

      checkOnLoadOnly : yes
      condition       : (options, cb)->

        if KD.isLoggedIn()

          KD.singletons.computeController.requireMachine
            app       :
              name    : APPNAME
              version : VERSION
          , (err, machine)->

            if err or not machine then cb no
            else cb yes, { machine }

        else

          cb no

      failure         : (options, cb)->

        KD.singletons.router.handleRoute "/Activity/Public"
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

    { machine }     = options.params
    options.machine = machine
    options.view    = new DevToolsMainView { machine }
    options.appInfo =
      name     : "DevTools"
      type     : "application"

    super options, data

  # FIXME facet, to make it work I had to call notifyWindowResizeListeners here
  handleQuery:->

    return unless view = @getView()
    {workspace, _currentMode} = view

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
