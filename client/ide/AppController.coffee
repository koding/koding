class IDEAppController extends AppController

  KD.registerAppClass this,
    name         : 'IDE'
    route        : '/:name?/IDE'
    behavior     : 'application'
    preCondition :
      condition  : (options, cb) -> cb KD.isLoggedIn()
      failure    : (options, cb) ->
        KD.getSingleton('appManager').open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()
    commands:
      'split vertically'    : 'splitVertically'
      'split horizontally'  : 'splitHorizontally'
      'merge splitview'     : 'mergeSplitView'
      'create new file'     : 'createNewFile'
      'create new terminal' : 'createNewTerminal'
      'create new browser'  : 'createNewBrowser'
      'create new drawing'  : 'createNewDrawing'
      'collapse sidebar'    : 'collapseSidebar'
      'expand sidebar'      : 'expandSidebar'
      'close tab'           : 'closeTab'
      'go to left tab'      : 'goToLeftTab'
      'go to right tab'     : 'goToRightTab'
      'go to tab number'    : 'goToTabNumber'
    keyBindings: [
      { command: 'split vertically',    binding: 'ctrl+alt+v', global: yes }
      { command: 'split horizontally',  binding: 'ctrl+alt+h', global: yes }
      { command: 'merge splitview',     binding: 'ctrl+alt+m', global: yes }
      { command: 'create new file',     binding: 'ctrl+alt+n', global: yes }
      { command: 'create new terminal', binding: 'ctrl+alt+t', global: yes }
      { command: 'create new browser',  binding: 'ctrl+alt+b', global: yes }
      { command: 'create new drawing',  binding: 'ctrl+alt+d', global: yes }
      { command: 'collapse sidebar',    binding: 'ctrl+alt+c', global: yes }
      { command: 'expand sidebar',      binding: 'ctrl+alt+e', global: yes }
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
        @registerIDEView ideView

        splitViewPanel = ideView.parent.parent
        splitViewPanel.addSubView @statusBar = new IDE.StatusBar

        appView.emit 'KeyViewIsSet'

  setActiveTabView: (tabView) ->
    @activeTabView = tabView

  splitTabView: (type = 'vertical') ->
    ideView        = @activeTabView.parent
    ideParent      = ideView.parent
    newIDEView     = new IDE.IDEView
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

    splitView.merge()

  handleSplitMerge: (views, container, parentSplitView, panelIndexInParent) ->
    ideView = new IDE.IDEView
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

  openFile: (file, contents) ->
    @activeTabView.emit 'FileNeedsToBeOpened', file, contents

  openVMTerminal: (vmData) ->
    @activeTabView.emit 'VMTerminalRequested', vmData

  openVMWebPage: (vmData) ->
    @activeTabView.emit 'VMWebPageRequested', vmData

  mountVM: (vmData) ->
    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'
    filesPane.emit 'VMMountRequested', vmData

  unmountVM: (vmData) ->
    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'
    filesPane.emit 'VMUnmountRequested', vmData

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
      file     = FSHelper.createFileFromPath "localfile://Untitled-#{newFileSeed++}.txt"
      contents = ''

      @openFile file, contents

  createNewTerminal: -> @activeTabView.emit 'TerminalPaneRequested'

  createNewBrowser: -> @activeTabView.emit 'PreviewPaneRequested'

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

    keyCodeMap    = [ 49, 50, 51, 52, 53, 54, 55, 56, 57 ]
    requiredIndex = keyCodeMap.indexOf keyEvent.keyCode

    @activeTabView.showPaneByIndex requiredIndex

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

  showActionsMenu: (button) ->
    paneView   = @getActivePaneView()
    paneType   = paneView?.getOptions().paneType or null
    menu       = new IDE.StatusBarMenu
      paneType : paneType
      delegate : button

    menu.on 'viewAppended', ->
      if paneType is 'editor' and paneView
        {syntaxSelector} = menu
        {ace}            = paneView.aceView

        syntaxSelector.select.setValue ace.getSyntax()
        syntaxSelector.on 'SelectionMade', (value) =>
          ace.setSyntax value

  getActivePaneView: ->
    return @activeTabView.getActivePane().getSubViews().first

  saveFile: ->
    @getActivePaneView().emit 'SaveRequested'

  saveAllFiles: ->
    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      editorPane.emit 'SaveRequested'

  updateStatusBar: (component, data) ->
    {status, menuButton} = @statusBar

    if component is 'editor'
      {cursor, file} = data
      text = """
        <p class="line">#{++cursor.row}:#{++cursor.column}</p>
        <p>#{file.name}</p>
      """

    else if component is 'terminal'
      text = "Terminal on #{data.vmName}"

    else if typeof data is 'string' then text = data

    else text = ''

    status.updatePartial text
    menuButton.show()

  doResize: ->
    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      editorPane.aceView.ace.editor.resize()
