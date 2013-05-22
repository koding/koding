class StartTabMainView extends JView

  constructor:(options = {}, data)->

    options.cssClass or= 'start-tab'

    super options, data

    @listenWindowResize()

    @appIcons       = {}
    mainView        = @getSingleton('mainView')

    @appStorage = @getSingleton('mainController') \
                    .getAppStorageSingleton 'Finder', '1.0'

    @appsController = @getSingleton("kodingAppsController")
    @appsController.on "AppsRefreshed", (apps)=>
      @decorateApps apps
    @appsController.on "aNewAppCreated", =>
      @aNewAppCreated()

    finder = @getSingleton("finderController")
    finder.on 'recentfiles.updated', =>
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
    # finder = @getSingleton("finderController").treeController
    # finder.refreshFolder finder.nodes["/home/#{KD.whoami().profile.nickname}/Applications"]

  pistachio:->
    """
    <div class='app-list-wrapper'>
      <div class='app-button-holder'>
        {{> @addAnAppButton}}
        {{> @refreshButton}}
      </div>
      <header>
        <h1 class="start-tab-header loaded hidden">To start from a new file, select an editor</h1>
        <h2 class="loaded hidden">or open an existing file from your file tree</h2>
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
      @getSingleton('mainController').on "NoSuchFile", (file)=>
        recentFilePaths.splice recentFilePaths.indexOf(file.path), 1
        @appStorage.setValue 'recentFiles', recentFilePaths, ->
          log "Storage updated for recent files"

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
