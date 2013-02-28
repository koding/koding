# uncomplicate this - Sinan 7/2012
# rewriting this - Sinan 2/2013

class ApplicationManager extends KDObject

  @debug = yes
  log = (rest...)->
    if ApplicationManager.debug
      console.log rest...
    else
      noop

  ###

  * EMITTED EVENTS
    - AppDidInitiate              [appController, appView, appOptions]
    - AppDidShow                  [appController, appView, appOptions]
    - AppDidQuit                  [appOptions]
    - AppManagerWantsToShowAnApp  [appController, appView, appOptions]
  ###

  appControllers: {}

  constructor:->

    super

    @frontApp = null

    @on 'AppManagerWantsToShowAnApp', @bound "setFrontApp"

  open: do ->

    createOrShow = (appOptions, callback = noop)->

      appManager  = KD.getSingleton "appManager"
      {name}      = appOptions
      appInstance = appManager.get name
      cb          = -> appManager.show appOptions, callback
      if appInstance then do cb
      else appManager.create name, cb

    (name, options, callback)->

      [callback, options] = [options, callback] if 'function' is typeof options

      options or= {}

      log options, ">>>"

      return warn "ApplicationManager::open called without an app name!"  unless name

      appOptions      = KD.getAppOptions name
      defaultCallback = -> createOrShow appOptions, callback

      if appOptions.multiple

        if options.forceNew
          @create name, @bound "showInstance"
          return

        switch appOptions.openWith
          when "lastActive" then do defaultCallback
          when "prompt"
            @createPromptModal appOptions, (appInstance)=>
              if appInstance
                @show appInstance, callback
              else
                @create name, callback

      else do defaultCallback

  tell:(name, command, rest...)->

    return warn "ApplicationManager::tell called without an app name!"  unless name

    log "::: Telling #{command} to #{name}"

    app = @get name
    cb  = (appInstance)-> appInstance?[command]? rest...

    if app then cb app
    else @create name, (appInstance)->  cb appInstance

  create:(name, callback)->

    AppClass   = KD.getAppClass name
    appOptions = KD.getAppOptions name
    log "::: Creating #{name}"
    @register appInstance = new AppClass appOptions  if AppClass
    callback? appInstance

    return appInstance

  show:(appOptions, callback)->

    return if appOptions.background

    appInstance = @get appOptions.name
    appView     = appInstance.getView?() or null
    log "::: Show #{appOptions.name}"

    if KD.isLoggedIn()
      @emit 'AppManagerWantsToShowAnApp', appInstance, appView, appOptions
      callback? appInstance
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes

  showInstance:(appInstance, callback)->

    appView    = appInstance.getView?() or null
    appOptions = KD.getAppOptions appInstance.getOption "name"

    return if appOptions.background

    if KD.isLoggedIn()
      @emit 'AppManagerWantsToShowAnApp', appInstance, appView, appOptions
      callback? appInstance
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes

  quit:(appInstance, callback = noop)->

    @unregister appInstance
    callback()

  get:(name)-> @appControllers[name]?.first or null

  getByView: (view)->

    appInstance = null
    for name, apps of @appControllers
      apps.forEach (appController)=>
        if view.getId() is appController.getView?().getId()
          appInstance = appController

    return appInstance

  getFrontApp:-> @frontApp

  setFrontApp:(@frontApp)->

  register:(appInstance)->

    name = appInstance.getOption "name"
    @appControllers[name] ?= []
    @appControllers[name].push appInstance
    @setListeners appInstance

  unregister:(appInstance)->

    name  = appInstance.getOption "name"
    index = @appControllers[name].indexOf appInstance

    if index >= 0
      @appControllers[name].splice index, 1
      if @appControllers[name].length is 0
        delete @appControllers[name]
      appInstance.destroy()

  createPromptModal:(appOptions, callback)->
    # show modal and wait for response
    callback appInstance

  setListeners:(appInstance)->

    appView = appInstance.getView?()
    appView?.once "KDObjectWillBeDestroyed", =>
      @unregister appInstance






  # setGroup:-> console.log 'setGroup', arguments

  openFile:(file)->
    @openFileWithApplication file, 'Ace'

  openFileWithApplication:(file, appPath)->
    @open appPath, no, (app)->
      app.openFile file

  # temp
  notification = null

  notify:(msg)->

    notification.destroy() if notification

    notification = new KDNotificationView
      title     : msg or "Currently disabled!"
      type      : "mini"
      duration  : 2500











  # deprecate these

  fetchStorage: (appId, version, callback) ->
    # warn "System still trying to access application storage for #{appId}"
    KD.whoami().fetchStorage {appId, version}, (error, storage) =>
      unless storage
        storage = {appId,version,bucket:{}} # creating a fake storage
      callback error, storage