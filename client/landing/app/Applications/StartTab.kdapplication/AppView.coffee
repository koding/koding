class StartTabMainView extends JView

  constructor:(options = {}, data)->

    options.cssClass or= 'start-tab'

    super options, data

    @listenWindowResize()

    @appIcons = {}
    mainView  = KD.getSingleton('mainView')

    @appStorage     = KD.getSingleton('appStorageController').storage 'Finder', '1.1'
    @appsController = KD.getSingleton("kodingAppsController")

    @appsController.on "AppsRefreshed", (apps)=>
      @decorateApps apps

    @appsController.on "AppsDataChanged", @bound "updateAppIcons"
    @appsController.on "InvalidateApp", @bound "removeAppIcon"
    @appsController.on "UpdateAppData", @bound "createAppIcon"

    @finderController = KD.getSingleton "finderController"
    @finderController.on 'recentfiles.updated', =>
      @updateRecentFileViews()

    @loader = new KDLoaderView size : width : 16

    @on 'refreshAppsMenuItemClicked', =>
      @appsController.syncAppStorageWithFS yes

    @on 'makeANewAppMenuItemClicked', =>
      @appsController.makeNewApp()

    @appItemContainer = new StartTabAppItemContainer
      cssClass : 'app-item-container'
      delegate : @

    @recentFilesWrapper = new KDView
      cssClass : 'file-container'

    @downloadFilesLink = new KDCustomHTMLView
    userJoinDate       = new Date(KD.whoami().meta.createdAt).getTime()
    oldKodingDownDate  = 1374267600000

    if userJoinDate < oldKodingDownDate
      @appStorage.fetchStorage (err, storage) =>
        return if @appStorage.getValue "HideOldKodingDownloadLink"

        @downloadFilesLink.addSubView text = new KDCustomHTMLView
          cssClass     : "download-files-link"
          partial      : "Click here to get download link for your old Koding files"
          click        : ->
            KD.whoami().fetchOldKodingDownloadLink (err, url) ->
              modal          = new KDModalView
                cssClass     : "modal-with-text old-file-download-modal"
                overlay      : yes
                title        : "Your old Koding files"
                content      : """
                  <p>
                    You can use the following link to download your files. Note that these files won't be available after Sep 1, 2013. You have to download before then.
                    <a href="#{url}" class="download-link" target="_blank">#{url}</a>
                  </p>
                """
                buttons      :
                  Close      :
                    title    : "Close"
                    cssClass : "modal-cancel"
                    callback : -> modal.destroy()

        text.addSubView new KDCustomHTMLView
          cssClass : "close-download-notification"
          tagName  : "span"
          tooltip  :
            title  : "Don't show this again."
          click    : (e) =>
            e.stopPropagation()
            @downloadFilesLink.destroy()
            @appStorage.setValue "HideOldKodingDownloadLink", yes

  showLoader:->

    @loader.show()
    @$('h1.loaded, h2.loaded').addClass "hidden"
    @$('h2.loader').removeClass "hidden"

  hideLoader:->

    @loader.hide()
    @$('h2.loader').addClass "hidden"
    @$('h1.loaded, h2.loaded').removeClass "hidden"

  viewAppended:->

    super

    @addRealApps()
    @addSplitOptions()
    @addRecentFiles()

    if KD.isGuest()
      unless $.cookie "guestForFirstTime"
        @utils.wait 5*60*1000, =>
          @showGuestNotification()
          $.cookie "guestForFirstTime", yes
      else
        @showGuestNotification()

  _windowDidResize:->

  pistachio:->
    """
    <div class='app-list-wrapper'>
      <header>
        <h1 class="start-tab-header loaded hidden">This is your Development Area</h1>
        <h2 class="loaded hidden">You can install more apps on Apps section, or use the ones below that are already installed.</h2>
        <h2 class="loader">{{> @loader}} Loading applications...</h1>
      </header>
      {{> @appItemContainer}}
    </div>
    <div class='start-tab-split-options expanded'>
      <h3>Start with a workspace</h3>
    </div>
    <div class='start-tab-recent-container'>
      <h3>Recent files:</h3>
      {{> @recentFilesWrapper}}
    </div>
    """

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

      for shortcut, manifest of shortcuts
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
    return warn "App icon not found for #{appName}"  unless appIcon
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
    for app, appData of apps
      do (app, appData)=>
        @createAppIcon app, appData, yes

    # To make sure its always the last icon
    @createGetMoreAppsButton()

  addSplitOptions:->
    for splitOption in getSplitOptions()
      option = new KDCustomHTMLView
        tagName   : 'a'
        cssClass  : 'start-tab-split-option'
        partial   : splitOption.partial
        click     : -> KD.getSingleton("appManager").notify()
      @addSubView option, '.start-tab-split-options'

  addRecentFiles:->

    @recentFileViews = {}

    @appStorage.fetchValue 'recentFiles', (recentFilePaths)=>
      recentFilePaths or= []
      @updateRecentFileViews()
      @finderController.on "NoSuchFile", (file)=>
        recentFilePaths.splice recentFilePaths.indexOf(file.path), 1
        @appStorage.setValue 'recentFiles', recentFilePaths

  updateRecentFileViews:(recentFilePaths)->

    @recentFileViews or= {}
    recentFilePaths   ?= @appStorage.getValue('recentFiles') or []

    for path, view of @recentFileViews
      @recentFileViews[path].destroy()
      delete @recentFileViews[path]

    if recentFilePaths.length
      recentFilePaths.forEach (filePath)=>
        @recentFileViews[filePath] = new StartTabRecentFileItemView {}, filePath
        @recentFilesWrapper.addSubView @recentFileViews[filePath]
    else
      @recentFilesWrapper.hide()

  createSplitView:(type)->

  getSplitOptions = ->
    [
      {
        partial               : '<span class="fl w50"></span><span class="fr w50"></span>'
        splitType             : 'vertical'
        splittingFromStartTab : yes
        splits                : [1,1]
      },
      {
        partial               : '<span class="fl h50 w50"></span><span class="fr h50 w50"></span><span class="h50 full-b"></span>'
        splitType             : 'horizontal'
        secondSplitType       : 'vertical'
        splittingFromStartTab : yes
        splits                : [2,1]
      },
      {
        partial               : '<span class="h50 full-t"></span><span class="fl w50 h50"></span><span class="fr w50 h50"></span>'
        splitType             : 'horizontal'
        secondSplitType       : 'vertical'
        splittingFromStartTab : yes
        splits                : [1,2]
      },
      {
        partial               : '<span class="fl w50 h50"></span><span class="fr w50 full-r"></span><span class="fl w50 h50"></span>'
        splitType             : 'vertical'
        secondSplitType       : 'horizontal'
        splittingFromStartTab : yes
        splits                : [2,1]
      },
      {
        partial               : '<span class="fl w50 full-l"></span><span class="fr w50 h50"></span><span class="fr w50 h50"></span>'
        splitType             : 'vertical'
        secondSplitType       : 'horizontal'
        splittingFromStartTab : yes
        splits                : [1,2]
      },
      {
        partial               : '<span class="fl w50 h50"></span><span class="fr w50 h50"></span><span class="fl w50 h50"></span><span class="fr w50 h50"></span>'
        splitType             : 'vertical'
        secondSplitType       : 'horizontal'
        splittingFromStartTab : yes
        splits                : [2,2]
      },
    ]

  showGuestNotification: (guestTimeout = 20)->
    return  unless KD.isGuest()
    guestCreate      = new Date KD.whoami().meta.createdAt
    guestCreateTime  = guestCreate.getTime()

    endTime       = new Date(guestCreateTime + guestTimeout*60*1000)
    log endTime
    notification  = new GlobalNotification
      title       : "Your session will end in"
      targetDate  : endTime
      endTitle    : "Your session end, logging out."
      content     : "You can use Koding for 20 minutes without registering. <a href='/Register'>Register now</a>."
      callback    : =>
        return  unless KD.isGuest()
        {defaultVmName} = KD.getSingleton "vmController"
        KD.remote.api.JVM.removeByHostname defaultVmName, (err)->
          KD.getSingleton("finderController").unmountVm defaultVmName
          KD.getSingleton("vmController").emit 'VMListChanged'
          $.cookie "clientId", erase: yes
          $.cookie "guestForFirstTime", erase: yes