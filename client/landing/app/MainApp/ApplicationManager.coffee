# uncomplicate this - Sinan 7/2012
# rewriting this - Sinan 2/2013

class ApplicationManager extends KDObject

  constructor: ->

    # @openedInstances = {}
    # @appInstances    = []
    # @appViews2d      = []
    # @openTabs        = []
    @appControllers  = {}

    super

  setGroup:-> console.log 'setGroup', arguments

  # expandApplicationPath = (path)->
  #   path ?= KD.getSingleton('mainController').getOptions().startPage
  #   if /\.kdapplication$/.test path then path
  #   else "./client/app/Applications/#{path}.kdapplication"

  isAppUnderDevelop:(appName)->

    appsWithCustomRoutes = [
      'Activity','Topics','Groups','Apps','Members','Inbox','Feeder'
      'Account','Chat','Demos'
    ]

    return !(appName in appsWithCustomRoutes)

  openApplication:do->

    openAppHandler =(app, appName, doBringToFront, callback)->
      if 'function' is typeof callback then @utils.defer -> callback app
      if doBringToFront
        @registerAppListeners app
        app.bringToFront()

    (appName, doBringToFront, callback)->
      # console.trace()
      [callback, doBringToFront] = [doBringToFront, callback]  unless callback
      doBringToFront ?= yes

      appName or= KD.getSingleton('mainController').getOptions().startPage
      app       = @getAppInstance appName

      if app? then openAppHandler.call @, app, appName, doBringToFront, callback
      else # this is the first time the app is opened.
        @createAppInstance appName, (app)=>
          openAppHandler.call @, app, appName, doBringToFront, callback

  registerAppListeners:(appController)->

    appController.once "ApplicationWantsToBeShown", @bound "applicationWantsToBeShown"
    appController.once "ControllerHasSetItsView",  => #@bound "applicationIsBeingClosed"

      log appController.getView(), "go to hell x 3"

  applicationWantsToBeShown:(appController, appView, options)->

    # log "ApplicationWantsToBeShown", appController, appView, options
    if KD.isLoggedIn()
      @emit 'AppViewAddedToAppManager', appController, appView, options
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes

  applicationIsBeingClosed:(appController, appView, options)->

    log "applicationIsBeingClosed", appController, apxpView, options

    # controllerIndex = @appInstances.indexOf appController
    # appViews        = @appViews2d[controllerIndex]
    # viewIndex       = appViews.indexOf appView
    # log @appViews2d[controllerIndex].splice viewIndex, 1
    @emit 'AppViewRemovedFromAppManager', appController, appView, options

  openFile:(file)->
    @openFileWithApplication file, 'Ace'

  openFileWithApplication:(file, appPath)->
    @openApplication appPath, no, (app)->
      # log app, file
      app.openFile file

  tell:(path, command, rest...)->
    @openApplication path, no, (app)-> app?[command]? rest...

  getAllAppInstances:-> @openedInstances

  createAppInstance:(appName, callback)->

    AppClass    = KD.getAppClass appName
    if AppClass
      appInstance = new AppClass
      @addAppInstance appName, appInstance

    callback appInstance or null

    # if app?
    #   @addAppInstance path, app
    #   callback app
    # else
    #   appSrc = "js/KDApplications/#{path}/AppController.js?#{KD.version}"
    #   requirejs [appSrc], (app)->
    #     if app
    #       KD.getSingleton("appManager").addAppInstance path, app
    #       callback app
    #     else
    #       callback new Error "Application does not exist!"
    #       new KDNotificationView title : "Application does not exist!"

  addAppInstance:(path, instance)->
    @appControllers[path] ?= []
    @appControllers[path].push instance
    # @appInstances.push instance
    # @appViews2d.push []
    # @openedInstances[path] = instance

  getAppInstance: (path) ->
    @appControllers[path]?.first or null
    # @openedInstances[expandApplicationPath path]

  removeAppInstance:(path)->
    app = @getAppInstance path
    # index = @appInstances.indexOf app
    # @appInstances.splice index, 1
    # @appViews2d.splice index, 1
    # delete @openedInstances[path]

  getAppViews:(path)->
    # index = @appInstances.indexOf @getAppInstance path
    # @appViews2d[index]

  addOpenTab:(tab, controller)-> @openTabs.push tab

  getOpenTabs:()-> @openTabs

  removeOpenTab:(tab)-> @openTabs.splice (@openTabs.indexOf tab), 1

  quitAll:(callback)->

    @quitApplication path for own path of @getAllAppInstances()

    #FIXME: make this async -sah 1/3/12
    callback?()

  forceQuit:(path)->
    app   = @getAppInstance path
    views = (@getAppViews path)?.slice 0
    for view in views ? []
      app.emit 'ApplicationWantsToClose', app, view
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


  # temp
  notification = null

  notify:(msg)->

    notification.destroy() if notification

    notification = new KDNotificationView
      title     : msg or "Currently disabled!"
      type      : "mini"
      duration  : 2500











  # deprecate these

  # fakeRequire:(path)->

  #   classes =
  #     "./client/app/Applications/Activity.kdapplication" : ActivityAppController
  #     "./client/app/Applications/Topics.kdapplication"   : TopicsAppController
  #     "./client/app/Applications/Feeder.kdapplication"   : FeederAppController
  #     "./client/app/Applications/Members.kdapplication"  : MembersAppController
  #     # "./client/app/Applications/StartTab.kdapplication" : StartTabAppController
  #     "./client/app/Applications/Home.kdapplication"     : HomeAppController
  #     "./client/app/Applications/Account.kdapplication"  : AccountAppController
  #     "./client/app/Applications/Apps.kdapplication"     : AppsAppController
  #     "./client/app/Applications/Inbox.kdapplication"    : InboxAppController
  #     "./client/app/Applications/Demos.kdapplication"    : DemosAppController
  #     "./client/app/Applications/Ace.kdapplication"      : AceAppController
  #     "./client/app/Applications/Viewer.kdapplication"   : ViewerAppController
  #     "./client/app/Applications/WebTerm.kdapplication"  : WebTermController
  #     "./client/app/Applications/Groups.kdapplication"   : GroupsAppController

  #   return new classes[path]  if classes[path]?

  fetchStorage: (appId, version, callback) ->
    # warn "System still trying to access application storage for #{appId}"
    KD.whoami().fetchStorage {appId, version}, (error, storage) =>
      unless storage
        storage = {appId,version,bucket:{}} # creating a fake storage
      callback error, storage




  # appShowedAView:(app,{options,data})=>

  #   # log "!!! appShowedAView", app, options, data
  #   if KD.isLoggedIn()
  #     index = @appInstances.indexOf app
  #     @appViews2d[index].push data
  #     @emit 'ApplicationShowedAView', app
  #   else
  #     KD.getSingleton('router').handleRoute '/', replaceState: yes

  # appClosedAView:(app,{options,data}) =>

  #   # log "!!! appClosedAView", app, options, data
  #   index = @appInstances.indexOf app
  #   (views = @appViews2d[index]).splice (views.indexOf data), 1
