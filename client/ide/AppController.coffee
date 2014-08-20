class IDEAppController extends AppController

  KD.registerAppClass this,
    name         : 'IDE'
    behavior     : 'application'
    multiple     : yes
    preCondition :
      condition  : (options, cb) -> cb KD.isLoggedIn()
      failure    : (options, cb) ->
        KD.getSingleton('appManager').open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()
    commands:
      'find file by name'   : 'showFileFinder'
      'search all files'    : 'showContentSearch'
      'split vertically'    : 'splitVertically'
      'split horizontally'  : 'splitHorizontally'
      'merge splitview'     : 'mergeSplitView'
      'preview file'        : 'previewFile'
      'save all files'      : 'saveAllFiles'
      'create new file'     : 'createNewFile'
      'create new terminal' : 'createNewTerminal'
      'create new browser'  : 'createNewBrowser'
      'create new drawing'  : 'createNewDrawing'
      'collapse sidebar'    : 'collapseSidebar'
      'expand sidebar'      : 'expandSidebar'
      'toggle sidebar'      : 'toggleSidebar'
      'close tab'           : 'closeTab'
      'go to left tab'      : 'goToLeftTab'
      'go to right tab'     : 'goToRightTab'
      'go to tab number'    : 'goToTabNumber'
    keyBindings: [
      { command: 'find file by name',   binding: 'ctrl+alt+o', global: yes }
      { command: 'search all files',    binding: 'ctrl+alt+f', global: yes }
      { command: 'split vertically',    binding: 'ctrl+alt+v', global: yes }
      { command: 'split horizontally',  binding: 'ctrl+alt+h', global: yes }
      { command: 'merge splitview',     binding: 'ctrl+alt+m', global: yes }
      { command: 'preview file',        binding: 'ctrl+alt+p', global: yes }
      { command: 'save all files',      binding: 'ctrl+alt+s', global: yes }
      { command: 'create new file',     binding: 'ctrl+alt+n', global: yes }
      { command: 'create new terminal', binding: 'ctrl+alt+t', global: yes }
      { command: 'create new browser',  binding: 'ctrl+alt+b', global: yes }
      { command: 'create new drawing',  binding: 'ctrl+alt+d', global: yes }
      { command: 'collapse sidebar',    binding: 'ctrl+alt+c', global: yes }
      { command: 'expand sidebar',      binding: 'ctrl+alt+e', global: yes }
      { command: 'toggle sidebar',      binding: 'ctrl+alt+k', global: yes }
      { command: 'close tab',           binding: 'ctrl+alt+w', global: yes }
      { command: 'go to left tab',      binding: 'ctrl+alt+[', global: yes }
      { command: 'go to right tab',     binding: 'ctrl+alt+]', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+1', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+2', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+3', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+4', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+5', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+6', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+7', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+8', global: yes }
      { command: 'go to tab number',    binding: 'ctrl+alt+9', global: yes }
    ]

  constructor: (options = {}, data) ->

    options.appInfo =
      type          : 'application'
      name          : 'IDE'

    super options, data

    layoutOptions     =
      splitOptions    :
        direction     : 'vertical'
        name          : 'BaseSplit'
        sizes         : [ 234, null ]
        maximums      : [ 400, null ]
        views         : [
          {
            type      : 'custom'
            name      : 'filesPane'
            paneClass : IDE.IDEFilesTabView
          },
          {
            type      : 'custom'
            name      : 'editorPane'
            paneClass : IDE.IDEView
          }
        ]

    $('body').addClass 'dark' # for theming

    appView   = @getView()
    workspace = @workspace = new IDE.Workspace { layoutOptions }
    @ideViews = []

    workspace.once 'ready', =>
      panel = workspace.getView()
      appView.addSubView panel

      panel.once 'viewAppended', =>
        ideView = panel.getPaneByName 'editorPane'
        @setActiveTabView ideView.tabView
        @registerIDEView  ideView

        splitViewPanel = ideView.parent.parent
        @createStatusBar splitViewPanel
        @createFindAndReplaceView splitViewPanel

        appView.emit 'KeyViewIsSet'

    KD.singletons.appManager.on 'AppIsBeingShown', (app) =>
      # Temporary fix for IDE is not shown after
      # opening pages which uses old SplitView.
      # TODO: This needs to be fixed. ~Umut
      if app instanceof IDEAppController
        KD.singletons.windowController.notifyWindowResizeListeners()

  setActiveTabView: (tabView) ->
    @activeTabView = tabView

  splitTabView: (type = 'vertical', ideViewOptions) ->
    ideView        = @activeTabView.parent
    ideParent      = ideView.parent
    newIDEView     = new IDE.IDEView ideViewOptions
    @activeTabView = null

    ideView.detach()

    splitView   = new KDSplitView
      type      : type
      views     : [ null, newIDEView ]

    @registerIDEView newIDEView

    splitView.once 'viewAppended', ->
      splitView.panels.first.attach ideView
      splitView.panels[0] = ideView.parent
      splitView.options.views[0] = ideView

    ideParent.addSubView splitView
    @setActiveTabView newIDEView.tabView

    splitView.on 'ResizeDidStop', KD.utils.throttle 500, @bound 'doResize'

  mergeSplitView: ->
    panel     = @activeTabView.parent.parent
    splitView = panel.parent
    {parent}  = splitView

    return  unless panel instanceof KDSplitViewPanel

    if parent instanceof KDSplitViewPanel
      parentSplitView    = parent.parent
      panelIndexInParent = parentSplitView.panels.indexOf parent

    splitView.once 'SplitIsBeingMerged', (views) =>
      for view in views
        index = @ideViews.indexOf view
        @ideViews.splice index, 1

      @handleSplitMerge views, parent, parentSplitView, panelIndexInParent
      @doResize()

    splitView.merge()

  handleSplitMerge: (views, container, parentSplitView, panelIndexInParent) ->
    ideView = new IDE.IDEView createNewEditor: no
    panes   = []

    for view in views
      {tabView} = view

      for p in tabView.panes by -1
        {pane} = tabView.removePane p, yes
        panes.push pane

      view.destroy()

    container.addSubView ideView

    for pane in panes
      ideView.tabView.addPane pane

    @setActiveTabView ideView.tabView
    @registerIDEView ideView

    if parentSplitView and panelIndexInParent
      parentSplitView.options.views[panelIndexInParent] = ideView
      parentSplitView.panels[panelIndexInParent]        = ideView.parent

  openFile: (file, contents, callback = noop) ->
    @activeTabView.emit 'FileNeedsToBeOpened', file, contents, callback

  openMachineTerminal: (machineData) ->
    @activeTabView.emit 'MachineTerminalRequested', machineData

  openMachineWebPage: (machineData) ->
    @activeTabView.emit 'MachineWebPageRequested', machineData

  mountMachine: (machineData) ->
    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'
    filesPane.emit 'MachineMountRequested', machineData

  unmountMachine: (machineData) ->
    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'
    filesPane.emit 'MachineUnmountRequested', machineData

  mountMachineByMachineUId: (machineUId) ->
    computeController = KD.getSingleton 'computeController'
    container         = @getView()

    computeController.fetchMachines (err, machines) =>
      return KD.showError 'Something went wrong. Try again.'  if err

      for machine in machines when machine.uid is machineUId
        machineItem = machine

      if machineItem
        {state} = machineItem.status

        if state is 'Running'
          @mountMachine machineItem
          computeController.on "stop-#{machineItem._id}", (event) ->
            if event.status is 'Stopped'
              new IDE.MachineStateModal { state: 'Stopped', container }, machineItem
        else
          new IDE.MachineStateModal { state, container }, machineItem
      else
        new IDE.MachineStateModal { state: 'NotFound', container } , undefined

  collapseSidebar: ->
    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first
    filesPane    = panel.getPaneByName 'filesPane'
    {tabView}    = filesPane
    desiredSize  = 289

    splitView.once 'PanelSetToFloating', =>
      floatedPanel._lastSize = desiredSize
      @getView().setClass 'sidebar-collapsed'
      @isSidebarCollapsed = yes
      KD.getSingleton("windowController").notifyWindowResizeListeners()

    splitView.setFloatingPanel 0, 39
    tabView.showPaneByName 'Dummy'

    tabView.on 'PaneDidShow', (pane) ->
      return if pane.options.name is 'Dummy'
      splitView.showPanel 0
      floatedPanel._lastSize = desiredSize

    floatedPanel.on 'ReceivedClickElsewhere', ->
      KD.utils.defer ->
        splitView.setFloatingPanel 0, 39
        tabView.showPaneByName 'Dummy'

  expandSidebar: ->
    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first
    filesPane    = panel.getPaneByName 'filesPane'

    floatedPanel._lastSize = 250
    splitView.unsetFloatingPanel 0
    filesPane.tabView.showPaneByIndex 0
    floatedPanel.off 'ReceivedClickElsewhere'
    @getView().unsetClass 'sidebar-collapsed'
    @isSidebarCollapsed = no

  toggleSidebar: ->
    if @isSidebarCollapsed then @expandSidebar() else @collapseSidebar()

  splitVertically: ->
    @splitTabView 'vertical'

  splitHorizontally: ->
    @splitTabView 'horizontal'

  createNewFile: do ->
    newFileSeed = 1

    return ->
      path     = "localfile:/Untitled-#{newFileSeed++}.txt"
      file     = FSHelper.createFileInstance { path }
      contents = ''

      @openFile file, contents

  createNewTerminal: -> @activeTabView.emit 'TerminalPaneRequested'

  createNewBrowser: (url) ->
    url = ''  unless typeof url is 'string'
    @activeTabView.emit 'PreviewPaneRequested', url

  createNewDrawing: -> @activeTabView.emit 'DrawingPaneRequested'

  goToLeftTab: ->
    index = @activeTabView.getActivePaneIndex()
    return if index is 0

    @activeTabView.showPaneByIndex index - 1

  goToRightTab: ->
    index = @activeTabView.getActivePaneIndex()
    return if index is @activeTabView.length - 1

    @activeTabView.showPaneByIndex index + 1

  goToTabNumber: (keyEvent) ->
    keyEvent.preventDefault()
    keyEvent.stopPropagation()

    keyCodeMap    = [ 49..57 ]
    requiredIndex = keyCodeMap.indexOf keyEvent.keyCode

    @activeTabView.showPaneByIndex requiredIndex

  goToLine: ->
    @activeTabView.emit 'GoToLineRequested'

  closeTab: ->
    @activeTabView.removePane @activeTabView.getActivePane()

  registerIDEView: (ideView) ->
    @ideViews.push ideView

    ideView.on 'PaneRemoved', =>
      ideViewLength  = 0
      ideViewLength += ideView.tabView.panes.length  for ideView in @ideViews

      @statusBar.showInformation()  if ideViewLength is 0

  forEachSubViewInIDEViews_: (callback = noop, paneType) ->
    if typeof callback is 'string'
      [paneType, callback] = [callback, paneType]

    for ideView in @ideViews
      for pane in ideView.tabView.panes
        view = pane.getSubViews().first
        if paneType
          if view.getOptions().paneType is paneType
            callback view
        else
          callback view

  updateSettings: (component, key, value) ->
    # TODO: Refactor this method by passing component type to helper method.
    Class  = if component is 'editor' then IDE.EditorPane else IDE.TerminalPane
    method = "set#{key.capitalize()}"

    @forEachSubViewInIDEViews_ (view) ->
      if view instanceof Class
        if component is 'editor'
          view.aceView.ace[method] value
        else
          view.webtermView.updateSettings()

  showShortcutsView: ->
    @activeTabView.emit 'ShortcutsViewRequested'

  showStatusBarMenu: (button) ->
    paneView = @getActivePaneView()
    paneType = paneView?.getOptions().paneType or null
    delegate = button
    menu     = new IDE.StatusBarMenu { paneType, paneView, delegate }

    menu.on 'viewAppended', ->
      if paneType is 'editor' and paneView
        {syntaxSelector} = menu
        {ace}            = paneView.aceView

        syntaxSelector.select.setValue ace.getSyntax()
        syntaxSelector.on 'SelectionMade', (value) =>
          ace.setSyntax value

  getActivePaneView: ->
    return @activeTabView.getActivePane()?.getSubViews().first

  saveFile: ->
    @getActivePaneView().emit 'SaveRequested'

  saveAs: ->
    @getActivePaneView().aceView.ace.requestSaveAs()

  saveAllFiles: ->
    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      editorPane.emit 'SaveRequested'

  previewFile: ->
    view   = @getActivePaneView()
    {file} = view.getOptions()
    return unless file

    if FSHelper.isPublicPath file.path
      # FIXME: Take care of https.
      @createNewBrowser KD.getPublicURLOfPath FSHelper.getFullPath file
    else
      @notify 'File needs to be under ~/Web folder to preview.', 'error'

  updateStatusBar: (component, data) ->
    {status, menuButton} = @statusBar

    text = if component is 'editor'
      {cursor, file} = data
      """
        <p class="line">#{++cursor.row}:#{++cursor.column}</p>
        <p>#{file.name}</p>
      """

    else if component is 'terminal' then "Terminal on #{data.machineName}"

    else if component is 'searchResult'
    then """Search results for #{data.searchText}"""
    # then """ #{data.stats.numberOfSearchedFiles} for "#{data.searchText}", #{data.stats.numberOfMatches} found """

    else if typeof data is 'string' then data

    else ''

    status.updatePartial text
    menuButton.show()

  showFileFinder: ->
    return @fileFinder.input.setFocus()  if @fileFinder

    @fileFinder = new IDE.FileFinder
    @fileFinder.once 'KDObjectWillBeDestroyed', => @fileFinder = null

  showContentSearch: ->
    return @contentSearch.findInput.setFocus()  if @contentSearch

    @contentSearch = new IDE.ContentSearch
    @contentSearch.once 'KDObjectWillBeDestroyed', => @contentSearch = null
    @contentSearch.once 'ViewNeedsToBeShown', (view) =>
      @activeTabView.emit 'ViewNeedsToBeShown', view

  createStatusBar: (splitViewPanel) ->
    splitViewPanel.addSubView @statusBar = new IDE.StatusBar

  createFindAndReplaceView: (splitViewPanel) ->
    splitViewPanel.addSubView @findAndReplaceView = new AceFindAndReplaceView
    @findAndReplaceView.hide()
    @findAndReplaceView.on 'FindAndReplaceViewClosed', =>
      @getActivePaneView().aceView?.ace.focus()
      @isFindAndReplaceViewVisible = no

  showFindReplaceView: (withReplaceMode) ->
    view = @findAndReplaceView
    @setFindAndReplaceViewDelegate()
    @isFindAndReplaceViewVisible = yes
    view.setViewHeight withReplaceMode
    view.setTextIntoFindInput '' # FIXME: Set selected text if existss

  hideFindAndReplaceView: ->
    @findAndReplaceView.close no

  setFindAndReplaceViewDelegate: ->
    @findAndReplaceView.setDelegate @getActivePaneView()?.aceView or null

  showFindAndReplaceViewIfNecessary: ->
    if @isFindAndReplaceViewVisible
      @showFindReplaceView @findAndReplaceView.mode is 'replace'

  handleFileDeleted: (file) ->
    for ideView in @ideViews
      ideView.tabView.emit 'TabNeedsToBeClosed', file

  doResize: ->
    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      height = editorPane.getHeight()
      {ace}  = editorPane.aceView
      ace.setHeight height
      ace.editor.resize()

  notify: (title, cssClass = 'success', type = 'mini', duration = 4000) ->
    return unless title
    new KDNotificationView { title, cssClass, type, duration }
