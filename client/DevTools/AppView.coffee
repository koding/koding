class DevToolsMainView extends KDView

  COFFEE = "//cdnjs.cloudflare.com/ajax/libs/coffee-script/1.6.3/coffee-script.min.js"

  constructor:->
    super

    @storage   = KD.singletons.localStorageController.storage "DevTools"
    @liveMode  = @storage.getValue 'liveMode'
    @machine   = @getOption 'machine'

    unless @liveMode?
      @liveMode = yes
      @storage.setValue 'liveMode', @liveMode

    info "[DevTools] loaded with machine:", @machine

    @_currentMode = 'home'

  getToggleLiveReloadMenuView: (item, menu)->

    itemLabel = "#{if @liveMode then 'Disable' else 'Enable'} live compile"

    toggleLiveReload = new KDView
      partial : "<span>#{itemLabel}</span>"
      click   : =>
        @toggleLiveReload()
        menu.contextMenu.destroy()

    toggleLiveReload.on "viewAppended", ->
      toggleLiveReload.parent.setClass "default"

  getToggleFullscreenMenuView: (item, menu)->
    labels = [
      "Enter Fullscreen"
      "Exit Fullscreen"
    ]
    mainView = KD.getSingleton "mainView"
    state    = mainView.isFullscreen() or 0
    toggleFullscreen = new KDView
      partial : "<span>#{labels[Number state]}</span>"
      click   : =>
        mainView.toggleFullscreen()
        menu.contextMenu.destroy()

    toggleFullscreen.on "viewAppended", ->
      toggleFullscreen.parent.setClass "default"

  viewAppended:->

    @addSubView @workspace      = new CollaborativeWorkspace
      name                      : "Koding DevTools"
      delegate                  : this
      firebaseInstance          : "koding-dev-tools"
      panels                    : [
        title                   : "Koding DevTools"
        layout                  :
          direction             : "vertical"
          sizes                 : [ "264px", null ]
          splitName             : "BaseSplit"
          views                 : [
            {
              type              : "finder"
              name              : "finder"
              editor            : "JSEditor"
              machine           : @machine
              handleFileOpen    : (file, content) =>

                @switchMode 'develop'

                {CSSEditor, JSEditor} = @workspace.activePanel.panesByName

                switch FSHelper.getFileExtension file.path
                  when 'css', 'styl'
                  then editor = CSSEditor
                  else editor = JSEditor

                editor.openFile file, content

            }
            {
              type              : "split"
              options           :
                direction       : "vertical"
                sizes           : [ "50%", "50%" ]
                splitName       : "InnerSplit"
                cssClass        : "inner-split"
              views             : [
                {
                  type          : "split"
                  options       :
                    direction   : "horizontal"
                    sizes       : [ "50%", "50%" ]
                    splitName   : "EditorSplit"
                    cssClass    : "editor-split"
                  views         : [
                    {
                      type      : "custom"
                      name      : "JSEditor"
                      paneClass : DevToolsEditorPane
                      title     : "JavaScript"
                      machine   : @machine
                    }
                    {
                      type      : "custom"
                      name      : "CSSEditor"
                      title     : "Style"
                      paneClass : DevToolsCssEditorPane
                      machine   : @machine
                    }
                  ]
                }
                {
                  type          : "custom"
                  name          : "PreviewPane"
                  title         : "Preview"
                  paneClass     : CollaborativePane
                }
              ]
            }
          ]
      ]

    # DISABLE broadcastMessaging in workspace
    @workspace.broadcastMessage = noop

    @workspace.ready =>

      {JSEditor, CSSEditor, PreviewPane} = panes = @workspace.activePanel.panesByName

      innerSplit = @workspace.activePanel
        .layoutContainer.getSplitByName "InnerSplit"
      innerSplit.addSubView @welcomePage = new DevToolsWelcomePage delegate: this

      # Remove the resizer in baseSplit until KDSplitView fixed ~ GG
      baseSplit = @workspace.activePanel
        .layoutContainer.getSplitByName "BaseSplit"
      baseSplit.resizers?[0].destroy?()

      PreviewPane.header.addSubView PreviewPane.info = new KDView
        cssClass : "inline-info"
        partial  : "updating"

      @switchMode 'home'

      KD.singletons.vmController.ready =>

        JSEditor.ready =>

          JSEditor.codeMirrorEditor.on "change", \
            _.debounce (@lazyBound 'previewApp', no), 500

          JSEditor.on "RunRequested", @lazyBound 'previewApp', yes
          JSEditor.on "SaveAllRequested", @bound 'saveAll'
          JSEditor.on "AutoRunRequested", @bound 'toggleLiveReload'
          JSEditor.on "FocusedOnMe", => @_lastActiveEditor = JSEditor
          JSEditor.on "RecentFileLoaded", => @switchMode 'develop'

          @on 'saveAllMenuItemClicked', @bound 'saveAll'
          @on 'saveMenuItemClicked', =>
            @_lastActiveEditor?.handleSave()
          @on 'closeAllMenuItemClicked', =>
            delete @_lastActiveEditor
            @switchMode 'home'
            KD.utils.defer ->
              PreviewPane.container.destroySubViews()
              CSSEditor.closeFile(); JSEditor.closeFile()

          JSEditor.loadLastOpenFile()

        CSSEditor.ready =>

          CSSEditor.loadLastOpenFile()
          CSSEditor.codeMirrorEditor.on "change", \
            _.debounce (@lazyBound 'previewCss', no), 500

          CSSEditor.on "RunRequested", @lazyBound 'previewCss', yes
          CSSEditor.on "SaveAllRequested", @bound 'saveAll'
          CSSEditor.on "AutoRunRequested", @bound 'toggleLiveReload'
          CSSEditor.on "FocusedOnMe", => @_lastActiveEditor = CSSEditor

        JSEditor.ready => CSSEditor.ready => @emit 'ready'

        @on 'createMenuItemClicked',  @bound 'createNewApp'
        @on 'publishMenuItemClicked', @lazyBound 'publishCurrentApp', 'production'
        @on 'publishTestMenuItemClicked', @bound 'publishCurrentApp'
        @on 'compileMenuItemClicked', @bound 'compileApp'


  previewApp:(force = no)->

    return  if not force and not @liveMode
    return  if @_inprogress
    @_inprogress = yes

    {JSEditor, PreviewPane} = @workspace.activePanel.panesByName
    editorData = JSEditor.getData()
    extension = if editorData then editorData.getExtension() else 'coffee'

    if extension not in ['js', 'coffee']
      @_inprogress = no
      pc = PreviewPane.container
      pc.destroySubViews()
      pc.addSubView new DevToolsErrorPaneWidget {},
        error     :
          name    : "Preview not supported"
          message : "You can only preview .coffee and .js files."
      return

    PreviewPane.info.unsetClass 'fail'

    @compiler (coffee)=>

      code = JSEditor.getValue()

      PreviewPane.container.destroySubViews()
      window.appView = new KDView
      try

        switch extension
          when 'js' then eval code
          when 'coffee' then coffee.run code

        PreviewPane.info.updatePartial 'compiled'
        PreviewPane.info.setClass 'in'

        PreviewPane.container.addSubView window.appView

      catch error

        PreviewPane.info.updatePartial 'failed'
        PreviewPane.info.setClass 'fail in'

        try window.appView.destroy?()
        warn "Failed to run:", error

        PreviewPane.container.addSubView new DevToolsErrorPaneWidget {}, {code, error}

      finally

        delete window.appView
        @_inprogress = no
        KD.utils.wait 700, -> PreviewPane.info.unsetClass 'in'

  previewCss:(force = no)->

    return  if not force and not @liveMode

    {CSSEditor, PreviewPane} = @workspace.activePanel.panesByName

    @_css?.remove()

    @_css = $ "<style scoped></style>"
    @_css.html CSSEditor.getValue()

    PreviewPane.container.domElement.prepend @_css

  compiler:(callback)->

    return callback @coffee  if @coffee
    requirejs [COFFEE], (@coffee)=> callback @coffee

  compileApp:->

    {JSEditor, finder} = @workspace.activePanel.panesByName

    KodingAppsController.compileAppOnServer \
      JSEditor.getData()?.path, (err, app)->

        return warn err  if err
        return warn "NO APP?"  unless app

        {vm, path} = app
        finder.finderController.expandFolders "[#{vm}]#{path}", ->
          fileTree = finder.finderController.treeController
          fileTree.selectNode fileTree.nodes["[#{vm}]#{path}/index.js"]


  createNewApp:->

    KD.singletons.kodingAppsController.makeNewApp @machine, (err, data)=>

      return warn err  if err

      {appPath} = data
      {CSSEditor, JSEditor, finder} = @workspace.activePanel.panesByName

      {uid} = @machine
      finder.finderController.expandFolders "[#{uid}]#{appPath}/resources", ->
        fileTree = finder.finderController.treeController
        fileTree.selectNode fileTree.nodes["[#{uid}]#{appPath}"]

      JSEditor.loadFile  "#{appPath}/index.coffee"
      CSSEditor.loadFile "#{appPath}/resources/style.css"

      @switchMode 'develop'


  publishCurrentApp:(target='test')->

    {JSEditor} = @workspace.activePanel.panesByName
    path = JSEditor.getData()?.path

    unless path
      return new KDNotificationView
        title : "Open an application first"

    KodingAppsController.createJApp { path, target }, @publishCallback

  publishCallback:(err, app)->
    if err or not app
      warn err
      return new KDNotificationView
        title : "Failed to publish"

    new KDNotificationView
      title: "Published successfully!"

    KD.singletons
      .router.handleRoute "/Apps/#{app.manifest.authorNick}/#{app.name}"

  toggleLiveReload:(state)->

    if state?
    then @liveMode = state
    else @liveMode = !@liveMode

    new KDNotificationView
      title: if @liveMode then 'Live compile enabled' \
                          else 'Live compile disabled'

    @storage.setValue 'liveMode', @liveMode
    return  unless @liveMode

    KD.utils.defer =>
      @previewApp yes; @previewCss yes

  switchMode: (mode = 'develop')->

    @_currentMode = mode

    # FIXME welcomePage show/hide logic ~ GG
    switch mode
      when 'home'
        @welcomePage.show()
        KD.singletons.mainView.appSettingsMenuButton.hide()
        KD.utils.defer @welcomePage.lazyBound 'unsetClass', 'out'
      else
        @welcomePage.setClass 'out'
        KD.singletons.mainView.appSettingsMenuButton.show()
        KD.utils.wait 500, @welcomePage.bound 'hide'

  saveAll:->

    {JSEditor, CSSEditor} = @workspace.activePanel.panesByName
    CSSEditor.handleSave(); JSEditor.handleSave()
