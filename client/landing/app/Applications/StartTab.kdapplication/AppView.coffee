class StartTabMainView extends JView

  constructor:(options = {}, data)->

    options.cssClass or= 'start-tab'

    super options, data

    @listenWindowResize()

    @appIcons       = {}
    mainView        = KD.getSingleton('mainView')

    @appStorage = KD.getSingleton('appStorageController').storage 'Finder', '1.0'
    @appsController = KD.getSingleton("kodingAppsController")
    @appsController.on "AppsRefreshed", (apps)=>
      @decorateApps apps
    @appsController.on "aNewAppCreated", =>
      @aNewAppCreated()

    @finderController = KD.getSingleton "finderController"
    @finderController.on 'recentfiles.updated', =>
      @updateRecentFileViews()

    @loader = new KDLoaderView size : width : 16

    @refreshButton = new KDButtonView
      cssClass    : "editor-button refresh-apps-button"
      title       : "Refresh Apps"
      icon        : yes
      iconClass   : "refresh"
      loader      :
        diameter  : 16
      callback    : =>
        @removeAppIcons()
        @showLoader()
        @appsController.refreshApps (err, apps)=>
          @hideLoader()
          @refreshButton.hideLoader()

    @addAnAppButton = new KDButtonView
      cssClass    : "editor-button new-app-button"
      icon        : yes
      iconClass   : "plus-black"
      title       : "Make a new App"
      callback    : =>
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
      @appStorage = KD.getSingleton("appStorageController").storage "Finder", "1.0"

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

  addApps:->

    for app in apps
      @appItemContainer.addSubView new StartTabOldAppThumbView
        tab : @
      , app

  aNewAppCreated:->
    new KDNotificationView
      type     : "mini"
      cssClass : "success"
      title    : "App is created! Check your Applications folder!"

    @removeAppIcons()
    @showLoader()
    @appsController.refreshApps =>
      @hideLoader()

    # FIXME Use Default VM ~ GG
    # # Refresh Applications Folder
    # finder = KD.getSingleton("finderController").treeController
    # finder.refreshFolder finder.nodes["/home/#{KD.whoami().profile.nickname}/Applications"]

  pistachio:->
    """
    <div class='app-list-wrapper'>
      <div class='app-button-holder'>
        {{> @downloadFilesLink}}
        {{> @addAnAppButton}}
        {{> @refreshButton}}
      </div>
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
      @decorateApps apps

  decorateApps:(apps)->
    @removeAppIcons()
    @showLoader()
    @refreshButton.hide()
    @putAppIcons apps

    shortcuts = @appsController.appStorage.getValue 'shortcuts'

    for shortcut, manifest of shortcuts
      do (shortcut, manifest)=>
        @appItemContainer.addSubView @appIcons[manifest.name] = new AppShortcutButton
          delegate : @
        , manifest

    @appItemContainer.addSubView @appIcons['GET_MORE_APPS'] = new GetMoreAppsButton
      delegate : @
    @hideLoader()
    @refreshButton.show()

  removeAppIcons:->

    @appItemContainer.destroySubViews()
    @appIcons = {}

  putAppIcons:(apps)->

    for app, manifest of apps
      do (app, manifest)=>
        @appItemContainer.addSubView @appIcons[manifest.name] = new StartTabAppThumbView
          delegate : @
        , manifest

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

    console.log guestTimeout
    endTime       = new Date(guestCreateTime + guestTimeout*60*1000)
    log endTime
    notification  = new GlobalNotification
      title       : "Your session will end in"
      targetDate  : endTime
      endTitle    : "Your session end, logging out."
      content     : "You can use Koding for 20 minutes without registering. <a href='/Register'>Register now</a>."
      callback    : =>
        {defaultVmName} = KD.getSingleton "vmController"
        KD.remote.api.JVM.removeByHostname defaultVmName, (err)->
          KD.getSingleton("finderController").unmountVm defaultVmName
          KD.getSingleton("vmController").emit 'VMListChanged'
          $.cookie "clientId", erase: yes
          $.cookie "guestForFirstTime", erase: yes