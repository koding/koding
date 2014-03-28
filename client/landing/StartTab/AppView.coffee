class StartTabMainView extends JView

  constructor:(options = {}, data)->

    options.cssClass = 'start-tab'

    super options, data

    @appIcons   = {}
    appStorages = KD.getSingleton('appStorageController')
    @appStorage = appStorages.storage 'Finder', '1.2'
    @_connectAppsController()

    # Main view elements

    @loader = new KDLoaderView size : width : 12

    @appItemContainer = new StartTabAppItemContainer
      cssClass : 'app-item-container'
      delegate : this

    # Server Container
    @serverContainer = new EnvironmentsMainScene cssClass : 'animated'
    @serverContainer.setHeight 2

    @serverContainerToggle = new KDToggleButton
      style           : "kdwhitebtn"
      cssClass        : "server-container-handler"
      defaultState    : "Hide environments"
      states          : [
        title         : "Show environments"
        callback      : (cb)=>
          @serverContainer.setHeight 500
          @serverContainerToggle.setClass 'on-top'
          @utils.wait 460, => @serverContainer.scene.updateScene()
          cb()
      ,
        title         : "Hide environments"
        callback      : (cb)=>
          @serverContainer.setHeight 2
          @serverContainerToggle.unsetClass 'on-top'
          @serverContainer.domainCreateForm.emit "CloseClicked"
          cb()
      ]

    # REMOVE AFTER IMPLEMENTATION IS DONE ~ GG
    @utils.defer @serverContainerToggle.bound 'click'

  # Application Specific Operations

  _connectAppsController:->
    @appsController = KD.getSingleton("kodingAppsController")

    @appsController.on "AppsRefreshed",   (apps)=> @decorateApps apps
    @appsController.on "AppsDataChanged", @bound "updateAppIcons"
    @appsController.on "InvalidateApp",   @bound "removeAppIcon"
    @appsController.on "UpdateAppData",   @bound "createAppIcon"

    @on 'refreshAppsMenuItemClicked', =>
      @appsController.syncAppStorageWithFS yes
    @on 'makeANewAppMenuItemClicked', =>
      @appsController.makeNewApp()

  addRealApps:->

    @removeAppIcons()
    @showLoader()
    @appsController.fetchApps (err, apps)=>
      if not @appsController._loadedOnce and apps and Object.keys(apps).length > 0
        @appsController.syncAppStorageWithFS()
      @decorateApps apps

  decorateApps:(apps)->

    apps or= @appsController.getManifests()

    @removeAppIcons()
    @showLoader()

    @appsController.appStorage.fetchValue 'shortcuts', (shortcuts)=>

      for own shortcut, manifest of shortcuts
        do (shortcut, manifest)=>
          @appItemContainer.addSubView @appIcons[manifest.name] = new AppShortcutButton
            delegate : @
          , manifest

      @createAllAppIcons apps
      @createGetMoreAppsButton()

      @hideLoader()

  createGetMoreAppsButton:->
    @appIcons['GET_MORE_APPS']?.destroy()
    @appItemContainer.addSubView @appIcons['GET_MORE_APPS'] = new GetMoreAppsButton
      delegate : @

  removeAppIcon:(appName)->
    appIcon = @appIcons[appName]
    return  unless appIcon
    appIcon.destroy()
    delete @appIcons[appName]

  removeAppIcons:->

    @appItemContainer.destroySubViews()
    @appIcons = {}

  updateAppIcons:(changes)->

    {removedApps, newApps, existingApps, force} = changes
    return @decorateApps()  if force or existingApps.length is 0
    @removeAppIcon app  for app in removedApps
    @createAllAppIcons @appsController.getManifests()  if newApps.length > 0

  createAppIcon:(app, appData, bulk=no)->

    appData or= @appsController.getManifest app
    return  unless appData

    oldIcon = @appIcons[app]
    @appItemContainer.addSubView newIcon = new StartTabAppThumbView
      delegate : this
    , appData

    if oldIcon
      newIcon.$().insertAfter oldIcon.$()
      oldIcon.destroy()

    @appIcons[app] = newIcon

    # To make sure its always the last icon
    @createGetMoreAppsButton()  unless bulk

  createAllAppIcons:(apps)->
    for own app, appData of apps
      do (app, appData)=>
        @createAppIcon app, appData, yes

    # To make sure its always the last icon
    @createGetMoreAppsButton()

  # Guest Notifications if necessary
  #
  # We need to inform Guest users to register a new account in 20 min.

  startGuestTimer:->
    return  unless KD.isGuest()
    unless Cookies.get "guestForFirstTime"
      @utils.wait 5*60*1000, =>
        @showGuestNotification()
        Cookies.set "guestForFirstTime", yes
    else
      @showGuestNotification()

  showGuestNotification: (guestTimeout = 20)->
    return  unless KD.isGuest()
    guestCreate      = new Date KD.whoami().meta.createdAt
    guestCreateTime  = guestCreate.getTime()

    endTime       = new Date(guestCreateTime + guestTimeout*60*1000)

    notification  = new GlobalNotification
      title       : "Your session will end in"
      targetDate  : endTime
      endTitle    : "Your session end, logging out."
      content     : "Please <a href='/Register'>register</a> to continue using Koding."
      callback    : =>
        return  unless KD.isGuest()
        {defaultVmName} = KD.getSingleton "vmController"
        KD.remote.api.JVM.removeByHostname defaultVmName, (err)->
          KD.getSingleton("finderController").unmountVm defaultVmName
          KD.getSingleton("vmController").emit 'VMListChanged'
          Cookies.expire "clientId"
          Cookies.expire "guestForFirstTime"

  # Common parts

  showLoader:->

    @loader.show()
    @$('h2.application-loader').removeClass "hidden"

    @serverContainerToggle.setClass 'in'
    @serverContainer.setClass 'in'

  hideLoader:->

    @loader.hide()
    @$('h2.application-loader').addClass "hidden"

  viewAppended:->

    super
    @addRealApps()
    @startGuestTimer()

    @utils.wait 220, =>
      @serverContainer.scene.updateScene()
      @serverContainer.setHeight 500
      @serverContainerToggle.setClass 'on-top'

  pistachio:->
    """
    <div class='app-list-wrapper'>
      <header>
        <h1 class="start-tab-header loaded">This is your Development Area</h1>
        <h2 class="loaded">You can install more apps on Apps section, or use the ones below that are already installed.</h2>
      </header>
      {{> @serverContainerToggle}}
      {{> @serverContainer}}
      <h2 class="application-loader">{{> @loader}} Loading applications...</h2>
      {{> @appItemContainer}}
    </div>
    """
