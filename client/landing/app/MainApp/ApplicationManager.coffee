# uncomplicate this - Sinan 7/2012
# rewriting this - Sinan 2/2013

class ApplicationManager extends KDObject

  constructor: ->

    @appControllers  = {}

    super

  setGroup:-> console.log 'setGroup', arguments

  isAppUnderDevelop:(appName)->

    appsWithCustomRoutes = [
      'Activity','Topics','Groups','Apps','Members','Inbox','Feeder'
      'Account','Chat','Demos'
    ]

    return !(appName in appsWithCustomRoutes)

  openApplication:do->

    openAppHandler =(app, appName, doBringToFront, callback)->
      if 'function' is typeof callback then @utils.defer -> callback app
      if doBringToFront then app.bringToFront()


    (appName, doBringToFront, callback)->
      # console.trace()
      [callback, doBringToFront] = [doBringToFront, callback]  unless callback
      doBringToFront ?= yes

      appName  or= KD.getSingleton('mainController').getOptions().startPage
      appOptions = KD.getAppOptions appName

      unless appOptions.multiple
        app = @getAppInstance appName

      if app?
        openAppHandler.call @, app, appName, doBringToFront, callback
      else
        # this is the first time the app is opened.
        console.trace()
        @createAppInstance appName, (app)=>
          @registerAppListeners app
          openAppHandler.call @, app, appName, doBringToFront, callback

  registerAppListeners:(appController)->

    appController.once "ApplicationWantsToBeShown", @bound "applicationWantsToBeShown"
    appView = appController.getView?()
    appView?.once "KDObjectWillBeDestroyed", =>
      @applicationIsBeingClosed appController, appView

  applicationWantsToBeShown:(appController, appView, options)->

    if KD.isLoggedIn()
      @emit 'AppViewAddedToAppManager', appController, appView, options
    else
      KD.getSingleton('router').handleRoute '/', replaceState: yes

  applicationIsBeingClosed:(appController, appView, options)->

    log "applicationIsBeingClosed", appController, appView, options

    @removeAppInstance appController

    # @emit 'AppViewRemovedFromAppManager', appController, appView, options

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
      appInfo     = appInstance.getOption "appInfo"
      @addAppInstance appInfo, appInstance

    callback appInstance or null

  addAppInstance:(appInfo, instance)->
    {name} = appInfo
    @appControllers[name] ?= []
    @appControllers[name].push instance

  getAppInstance:(name) ->
    @appControllers[name]?.first or null

  removeAppInstance:(appController)->
    appInfo = appController.getOption "appInfo"
    {name}  = appInfo
    index   = @appControllers[name].indexOf appController

    # debugger
    if index >= 0
      @appControllers[name].splice index, 1
      if @appControllers[name].length is 0
        delete @appControllers[name]
      appController.destroy()

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
