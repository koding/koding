class DevToolsMainView extends KDView

  COFFEE = "//cdnjs.cloudflare.com/ajax/libs/coffee-script/1.6.3/coffee-script.min.js"

  constructor:->
    super

    @storage = KD.singletons.localStorageController.storage "DevTools"
    @liveMode = @storage.getAt 'liveMode'

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
      firebaseInstance          : "tw-local"
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
              handleFileOpen    : (file, content) =>

                @switchMode 'develop'

                {CSSEditor, JSEditor} = @workspace.activePanel.panesByName

                switch FSItem.getFileExtension file.path
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
                      # buttons : [
                      #   {
                      #     itemClass: KDOnOffSwitch
                      #     callback: ->
                      #       log arguments
                      #   }
                      # ]
                    }
                    {
                      type      : "custom"
                      name      : "CSSEditor"
                      title     : "Style"
                      paneClass : DevToolsCssEditorPane
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
      innerSplit.addSubView @welcomePage = new WelcomePage delegate: this

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
      pc.addSubView new ErrorPaneWidget {},
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

        PreviewPane.container.addSubView new ErrorPaneWidget {}, {code, error}

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
    require [COFFEE], (@coffee)=> callback @coffee

  compileApp:->

    {JSEditor} = @workspace.activePanel.panesByName

    KodingAppsController.compileAppOnServer JSEditor.getData()?.path, ->
      log "COMPILE", arguments

  createNewApp:->

    KD.singletons.kodingAppsController.makeNewApp (err, data)=>

      return warn err  if err

      {appPath} = data
      {CSSEditor, JSEditor, finder} = @workspace.activePanel.panesByName

      vmName = KD.singletons.vmController.defaultVmName
      finder.finderController.expandFolders "[#{vmName}]#{appPath}/resources", ->
        fileTree = finder.finderController.treeController
        fileTree.selectNode fileTree.nodes["[#{vmName}]#{appPath}"]

      JSEditor.loadFile  "[#{vmName}]#{appPath}/index.coffee"
      CSSEditor.loadFile "[#{vmName}]#{appPath}/resources/style.css"

      @switchMode 'develop'

  publishCurrentApp:(target='test')->

    {JSEditor} = @workspace.activePanel.panesByName
    path = JSEditor.getData()?.path

    unless path
      return new KDNotificationView
        title : "Open an application first"

    app = KodingAppsController.getAppInfoFromPath path
    options = {path}

    if target is 'production'

      modal = new KodingAppSelectorForGitHub
        title : "Select repository of #{app.name}.kdapp"
        customFilter : ///#{app.name}\.kdapp$///

      modal.on "RepoSelected", (repo)->
        options.githubPath = \
          "#{KD.config.appsUri}/#{repo.full_name}/#{repo.default_branch}"
        KodingAppsController.createJApp options, ->
          new KDNotificationView
            title: "Published successfully!"

    else

      KodingAppsController.createJApp options, ->
        new KDNotificationView
          title: "Published successfully!"

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


class DevToolsEditorPane extends CollaborativeEditorPane

  constructor:(options = {}, data)->

    options.defaultTitle or= 'JavaScript'
    options.editorMode   or= 'coffeescript'
    options.cssClass       = 'devtools-editor'
    super options, data

    @_mode = @getOption 'editorMode'
    @_defaultTitle = @getOption 'defaultTitle'

    @_lastFileKey = "lastFileOn#{@_mode}"
    @storage = KD.singletons.localStorageController.storage "DevTools"

  closeFile:->
    @openFile FSHelper.createFileFromPath 'localfile:/empty.coffee'

  loadFile:(path, callback = noop)->

    file = FSHelper.createFileFromPath path
    file.fetchContents (err, content)=>
      return callback err  if err

      file.path = path
      @openFile file, content

      KD.utils.defer -> callback null, {file, content}

  loadLastOpenFile:->

    path = @storage.getAt @_lastFileKey
    return  unless path

    @loadFile path, (err)=>
      if err?
      then @storage.unsetKey @_lastFileKey
      else @emit "RecentFileLoaded"

  loadAddons:(callback)->

    {cdnRoot} = CollaborativeEditorPane

    KodingAppsController.appendHeadElements
      identifier : "codemirror-addons"
      items      : [
        {
          type   : 'script'
          url    : "#{cdnRoot}/addon/selection/active-line.js"
        },
        {
          type   : 'style'
          url    : "#{cdnRoot}/addon/hint/show-hint.css"
        },
        {
          type   : 'script'
          url    : "#{cdnRoot}/addon/hint/show-hint.js"
        },
        {
          type   : 'script'
          url    : "#{cdnRoot}/addon/hint/coffeescript-hint.js"
        },
        {
          type   : 'script'
          url    : "#{cdnRoot}/addon/hint/css-hint.js"
        }
      ]
    , callback

  createEditor: (callback)->

    @loadAddons =>

      @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
        lineNumbers     : yes
        lineWrapping    : yes
        styleActiveLine : yes
        scrollPastEnd   : yes
        cursorHeight    : 1
        tabSize         : 2
        mode            : @_mode
        extraKeys       :
          "Cmd-S"       : @bound "handleSave"
          "Ctrl-S"      : @bound "handleSave"
          "Shift-Cmd-S" : => @emit "SaveAllRequested"
          "Shift-Ctrl-S": => @emit "SaveAllRequested"
          "Alt-R"       : => @emit "RunRequested"
          "Shift-Ctrl-R": => @emit "AutoRunRequested"
          "Ctrl-Space"  : (cm)->
            mode = CodeMirror.innerMode(cm.getMode()).mode.name
            if mode is 'coffeescript'
              CodeMirror.showHint cm, CodeMirror.coffeescriptHint
            else if mode is 'css'
              CodeMirror.showHint cm, CodeMirror.hint.css
          "Tab"         : (cm)->
            spaces = Array(cm.getOption("indentUnit") + 1).join " "
            cm.replaceSelection spaces, "end", "+input"

      @setEditorTheme 'xq-dark'
      @setEditorMode @_mode ? "coffee"

      callback?()

      @header.addSubView @info = new KDView
        cssClass : "inline-info"
        partial  : "saved"

      @on 'EditorDidSave', =>
        @info.updatePartial 'saved'; @info.setClass 'in'
        KD.utils.wait 1000, => @info.unsetClass 'in'

      @codeMirrorEditor.on 'focus', => @emit "FocusedOnMe"

  openFile: (file, content)->

    validPath = file instanceof FSFile and not /^localfile\:/.test file.path

    if validPath
    then @storage.setValue @_lastFileKey, file.path
    else @storage.unsetKey @_lastFileKey

    super

    path = (FSHelper.plainPath file.path).replace \
      "/home/#{KD.nick()}/Applications/", ""

    @header.title.updatePartial if not validPath then @_defaultTitle else path

class DevToolsCssEditorPane extends DevToolsEditorPane

  constructor: (options = {}, data)->

    options.editorMode   = 'css'
    options.defaultTitle = 'Style'

    super options, data

class ErrorPaneWidget extends JView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'error-pane', options.cssClass
    super options, data

  pistachio:->
    {error} = @getData()
    line    = if error.location then "at line: #{error.location.last_line+1}" else ""
    stack   = if error.stack? then """
      <div class='stack'>
        <h2>Full Stack</h2>
        <pre>#{error.stack}</pre>
      </div>
    """ else ""

    """
      {h1{#(error.name)}}
      <pre>#{error.message} #{line}</pre>
      #{stack}
    """

  click:-> @setClass 'in'

class WelcomePage extends JView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'welcome-pane', options.cssClass
    super options, data

    @buttons = new KDView
      cssClass : 'button-container'

    delegate = @getDelegate()
    @addButton title : "Create New", delegate.bound 'createNewApp'

  addButton:({title, type}, callback)->

    type ?= ""
    cssClass = "solid big #{type}"

    @buttons.addSubView new KDButtonView {
      title, cssClass, callback
    }

  pistachio:->
    """
      <h1>Welcome to Koding DevTools</h1>
      {{> @buttons}}
    """

  click:-> @setClass 'in'
