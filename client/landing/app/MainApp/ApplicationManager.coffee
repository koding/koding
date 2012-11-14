# uncomplicate this - Sinan 7/2012
class ApplicationManager extends KDObject
  constructor: ->
    @controllers            = {}
    @openedInstances        = {}
    @appInstanceArray       = []
    @appInitializationQueue = {}
    @appViewsArray          = []
    @openTabs               = []
    @activePath             = null

    @listenTo KDEventTypes : ['ApplicationWantsToBeShown'], callback: @appShowedAView
    @listenTo KDEventTypes : ['ApplicationWantsToClose'], callback: @appClosedAView
    super

  quitAll:(callback)->
    # log @openedInstances
    for own path of @getAllAppInstances()
      @quitApplication path

    #FIXME: make this async -sah 1/3/12
    callback?()

  forceQuit:(path)->
    appInstance = @getAppInstance path
    for view in (@getAppViews path).slice 0
      appInstance.propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : view
      view.destroy()
    @removeAppInstance path
    appInstance.destroy()

  quitApplication:(path)->
    appInstance = @getAppInstance path
    if typeof appInstance.quit is "function"
      appInstance.quit? ->
        @removeAppInstance path
      setTimeout ->
        @forceQuit path
      , 50000
    else
      @forceQuit path

  setFrontApp:(appInstance)->
    @frontApp = appInstance

  getFrontApp:-> @frontApp

  expandApplicationPath = (path)->
    path ?= KD.getSingleton('mainController').getOptions().startPage
    if /\.kdapplication$/.test path then path
    else "./client/app/Applications/#{path}.kdapplication"

  openApplication:do->
    openAppHandler =(appInstance, path, doBringToFront, callback)->
      @emit "AppManagerOpensAnApplication", appInstance
      if 'function' is typeof callback
        @utils.defer -> callback appInstance
      if doBringToFront
        appManager.setFrontApp path
        appInstance.bringToFront()

    (path, doBringToFront, callback)->
      [callback, doBringToFront] = [doBringToFront, callback] unless callback
      doBringToFront ?= yes

      path = expandApplicationPath path
      appManager = @

      # TODO: this isOpenOrInitializing crap is completely botched C.T.
      #application already open or initialization in process
      isOpenOrInitializing = @waitForAppInitialization path, (appInstance)=>
        openAppHandler.call @, appInstance, path, doBringToFront, callback
      #application needs opening
      unless isOpenOrInitializing
        @createAppInstance path, (appInstance)=>
          handler = openAppHandler.bind(
            @, appInstance, path, doBringToFront, callback
          )
          if doBringToFront and\
             "function" is typeof appInstance.initAndBringToFront
            appManager.initializeAppInstance(
              path, appInstance, 'initAndBringToFront', handler
            )
          else if "function" is typeof appInstance.initApplication
            appManager.initializeAppInstance(
              path, appInstance, 'initApplication', handler
            )
          else appManager.initializeAppInstance path, appInstance, handler

  replaceStartTabWithApplication:(applicationPath, tab)->
    @openApplication applicationPath, no, (appInstance)->
      appInstance.bringToFront()
      tabDelegate = tab.getDelegate()
      tabDelegate.closeTab tab

  # replaceStartTabWithSplit:(splitType, tab)->
  #   @openApplication 'Ace', no, (appInstance)->
  #     appInstance.createFreshSplit splitType
  #     tabDelegate = tab.getDelegate()
  #     tabDelegate.closeTab tab

  openFile:(file)->
    @openFileWithApplication file, 'Ace'

  newFileWithApplication:(applicationPath)->
    @openApplication applicationPath, no, (appInstance)->
      appInstance.bringToFront()
    # @openApplication applicationPath, no, (appInstance)->
    #   appInstance.newFile()

  openFileWithApplication:(file, applicationPath)->
    @openApplication applicationPath, no, (appInstance)->
      # log appInstance, file
      appInstance.openFile file

  tell:(path, command, rest...)->
    @openApplication path, no, (app)-> app?[command]? rest...

  fakeRequire:(path)->
    classes =
      "./client/app/Applications/Activity.kdapplication"    : Activity12345
      "./client/app/Applications/Topics.kdapplication"      : Topics12345
      "./client/app/Applications/Feeder.kdapplication"      : Feeder12345
      "./client/app/Applications/Members.kdapplication"     : Members12345
      "./client/app/Applications/StartTab.kdapplication"    : StartTab12345
      "./client/app/Applications/Home.kdapplication"        : Home12345
      "./client/app/Applications/Account.kdapplication"     : Account12345
      "./client/app/Applications/Environment.kdapplication" : Environment12345
      "./client/app/Applications/Apps.kdapplication"        : Apps12345
      "./client/app/Applications/Inbox.kdapplication"       : Inbox12345
      "./client/app/Applications/Demos.kdapplication"       : Demos12345
      "./client/app/Applications/Ace.kdapplication"         : Ace12345
      "./client/app/Applications/Chat.kdapplication"        : Chat12345
      "./client/app/Applications/Viewer.kdapplication"      : Viewer12345
      "./client/app/Applications/WebTerm.kdapplication"     : WebTermController
      "./client/app/Applications/Groups.kdapplication"      : GroupsController
    if classes[path]?
      new classes[path]

  setEnvironment:(@environment)->
    appInstance.setEnvironment? @environment for own index, appInstance of @getAllAppInstances()

  getEnvironment:()->
    @environment# or warn 'fdasfasdf'

  getAllAppInstances:->
    @openedInstances

  createAppInstance:(path, callback)->
    appManager = @

    # fake require (code is concatenated in codebase)
    if (appInstance = @fakeRequire path)?
      @addAppInstance path, appInstance
      callback appInstance
    else
      #real require, module needs to be loaded
      # @getEnvironment().getApplicationPath "KDApplications/#{path}/AppController.js", (appUrl, err)->
      #   if err then warn err
      #   else
      #     requirejs [appUrl], (appInstance)->
      #       callback appInstance
      requirejs ["js/KDApplications/#{path}/AppController.js?#{KD.version}"], (appInstance)->
        if appInstance
          appManager.addAppInstance path, appInstance
          callback appInstance
        else
          callback new KDNotificationView
            title : "Application does not exists!"

  initializeAppInstance:(path, appInstance, initFunctionName, callback)->
    appManager = @
    environment = @getEnvironment()
    [path, appInstance, callback, initFunctionName] = arguments unless callback?
    initFunction = appInstance[initFunctionName] or -> arguments[1]()
    initFunction.call appInstance, {environment}, -> callback appInstance
    appManager.passStorageToApp path, null, appInstance, ->

  addAppInstance:(path, instance)->
    @appInstanceArray.push instance
    @appViewsArray.push []
    @openedInstances[path] = instance

  getAppInstance: (path) ->
    @openedInstances[expandApplicationPath path]

  removeAppInstance:(path)->
    appInstance = @getAppInstance path
    index = @appInstanceArray.indexOf appInstance
    @appInstanceArray.splice index, 1
    @appViewsArray.splice index, 1
    delete @openedInstances[path]
    delete @appInitializationQueue[path]

  waitForAppInitialization:(path, callback)->
    if (appInstance = @getAppInstance path)?
      callback appInstance
      return yes
    return no

  getAppViews:(path)->

    index = @appInstanceArray.indexOf @getAppInstance path
    @appViewsArray[index]

  appShowedAView:(appInstance,{options,data})=>
    index = @appInstanceArray.indexOf appInstance
    @appViewsArray[index].push data
    @emit 'ApplicationShowedAView', appInstance

  appClosedAView:(appInstance,{options,data}) =>
    index = @appInstanceArray.indexOf appInstance
    (views = @appViewsArray[index]).splice (views.indexOf data), 1

  passStorageToApp:(path, version, appInstance, callback)->
    @fetchStorage path, version, (error, storage)->
      if error then warn 'error'
      else
        appInstance.setStorage? storage
        callback?()

  fetchStorage: (appId, version, callback) ->

    notifyView = null
    # warn "System still trying to access application storage for #{appId}"
    KD.whoami().fetchStorage {appId, version}, (error, storage) =>
      unless storage
        storage = {appId,version,bucket:{}} # creating a fake storage
      callback error, storage


  addOpenTab:(tab, controller)->
    # docManager.addOpenDocument tab.getActiveFile() if tab.getActiveFile?
    @openTabs.push tab

  getOpenTabs:()->
    @openTabs

  removeOpenTab:(tab)->
    # docManager.removeOpenDocument tab.getActiveFile() if tab.getActiveFile?
    @openTabs.splice (@openTabs.indexOf tab), 1

  # temp
  notification = null

  notify:(msg)->

    notification.destroy() if notification

    notification = new KDNotificationView
      title     : msg or "Currently disabled!"
      type      : "mini"
      duration  : 2500
