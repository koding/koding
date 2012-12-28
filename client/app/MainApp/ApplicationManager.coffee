# uncomplicate this - Sinan 7/2012
class ApplicationManager extends KDObject
  constructor: ->
    # @controllers            = {}
    @openedInstances        = {}
    @appInstances           = []
    @appViews2d             = []
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
    app = @getAppInstance path
    views = (@getAppViews path)?.slice 0
    for view in views ? []
      app.propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent : yes), data : view
      view.destroy()
    @removeAppInstance path
    app?.destroy()

  quitApplication:(path)->
    app = @getAppInstance path
    if app and typeof app.quit is "function"
      app.quit? ->
        @removeAppInstance path
      setTimeout ->
        @forceQuit path
      , 50000
    else
      @forceQuit path

  setFrontApp:(app)-> @frontApp = app

  getFrontApp:-> @frontApp

  expandApplicationPath = (path)->
    path ?= KD.getSingleton('mainController').getOptions().startPage
    if /\.kdapplication$/.test path then path
    else "./client/app/Applications/#{path}.kdapplication"

  isAppUnderDevelop:(appName)->

    appsWithCustomRoutes = [
      'Activity','Topics','Groups','Apps','Members','Inbox','Feeder'
      'Account','Chat','Demos'
    ]

    return !(appName in appsWithCustomRoutes)

  openApplication:do->

    openAppHandler =(app, path, doBringToFront, callback)->
      if 'function' is typeof callback then @utils.defer -> callback app
      if doBringToFront
        appManager.setFrontApp path
        app.bringToFront()

        # # TODO: this is a quick hack
        # appName = path.split(/(?:\/)|(?:\.kdapplication$)/).slice(-2,-1)[0]

        # router = @getSingleton('router')
        # appsWithCustomRoutes = [
        #   'Activity','Topics','Groups','Apps','Members','Inbox','Feeder'
        #   'Account','Chat','Demos'
        # ]
        # isBlacklisted = appName not in appsWithCustomRoutes
        # if isBlacklisted and 'Develop' isnt router?.getCurrentPath()
        #   router.handleRoute '/Develop', suppressListeners: yes

    openApplication =(path, doBringToFront, callback)->
      [callback, doBringToFront] = [doBringToFront, callback]  unless callback
      doBringToFront ?= yes

      path = expandApplicationPath path
      app = @getAppInstance path

      if app? then openAppHandler.call @, app, path, doBringToFront, callback
      else # this is the first time the app is opened.
        @createAppInstance path, (app)=>
          handler = openAppHandler.bind @, app, path, doBringToFront, callback
          @initApp path, app, handler

  replaceStartTabWithApplication:(appPath, tab)->
    @openApplication appPath, no, (app)->
      app.bringToFront()
      tabDelegate = tab.getDelegate()
      tabDelegate.closeTab tab

  # replaceStartTabWithSplit:(splitType, tab)->
  #   @openApplication 'Ace', no, (app)->
  #     app.createFreshSplit splitType
  #     tabDelegate = tab.getDelegate()
  #     tabDelegate.closeTab tab

  openFile:(file)->
    @openFileWithApplication file, 'Ace'

  newFileWithApplication:(appPath)->
    @openApplication appPath, no, (app)->
      app.bringToFront()
    # @openApplication appPath, no, (app)->
    #   app.newFile()

  openFileWithApplication:(file, appPath)->
    @openApplication appPath, no, (app)->
      # log app, file
      app.openFile file

  tell:(path, command, rest...)->
    @openApplication path, no, (app)-> app?[command]? rest...

  fakeRequire:(path)->
    classes =
      "./client/app/Applications/Activity.kdapplication"    : ActivityAppController
      "./client/app/Applications/Topics.kdapplication"      : TopicsAppController
      "./client/app/Applications/Feeder.kdapplication"      : FeederAppController
      "./client/app/Applications/Members.kdapplication"     : MembersAppController
      "./client/app/Applications/StartTab.kdapplication"    : StartTabAppController
      "./client/app/Applications/Home.kdapplication"        : HomeAppController
      "./client/app/Applications/Account.kdapplication"     : AccountAppController
      "./client/app/Applications/Apps.kdapplication"        : AppsAppController
      "./client/app/Applications/Inbox.kdapplication"       : InboxAppController
      "./client/app/Applications/Demos.kdapplication"       : DemosAppController
      "./client/app/Applications/Ace.kdapplication"         : AceAppController
      "./client/app/Applications/Viewer.kdapplication"      : ViewerAppController
      "./client/app/Applications/WebTerm.kdapplication"     : WebTermController
      "./client/app/Applications/Groups.kdapplication"      : GroupsAppController
    if classes[path]?
      new classes[path]

  setEnvironment:(@environment)->
    app.setEnvironment? @environment for own index, app of @getAllAppInstances()

  getEnvironment:()->
    @environment# or warn 'fdasfasdf'

  getAllAppInstances:->
    @openedInstances

  createAppInstance:(path, callback)->
    appManager = @

    # fake require (code is concatenated in codebase)
    app = @fakeRequire path

    if app?
      @addAppInstance path, app
      callback app
    else
      appSrc = "js/KDApplications/#{path}/AppController.js?#{KD.version}"
      requirejs [appSrc], (app)->
        if app
          appManager.addAppInstance path, app
          callback app
        else
          callback new Error "Application does not exist!"
          new KDNotificationView title : "Application does not exist!"

  initApp:(path, app, callback)->
    if app.initApp? then app.initApp {}, callback
    else callback()

    @passStorageToApp path, null, app

  addAppInstance:(path, instance)->
    @appInstances.push instance
    @appViews2d.push []
    @openedInstances[path] = instance

  getAppInstance: (path) ->
    @openedInstances[expandApplicationPath path]

  removeAppInstance:(path)->
    app = @getAppInstance path
    index = @appInstances.indexOf app
    @appInstances.splice index, 1
    @appViews2d.splice index, 1
    delete @openedInstances[path]

  getAppViews:(path)->
    index = @appInstances.indexOf @getAppInstance path
    @appViews2d[index]

  appShowedAView:(app,{options,data})=>
    if KD.isLoggedIn()
      index = @appInstances.indexOf app
      @appViews2d[index].push data
      @emit 'ApplicationShowedAView', app
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes


  appClosedAView:(app,{options,data}) =>
    index = @appInstances.indexOf app
    (views = @appViews2d[index]).splice (views.indexOf data), 1

  passStorageToApp:(path, version, app, callback)->
    @fetchStorage path, version, (error, storage)->
      if error then warn 'error'
      else
        app.setStorage? storage
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
