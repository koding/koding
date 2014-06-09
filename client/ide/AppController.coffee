class IDEAppController extends AppController

  KD.registerAppClass this,
    name         : 'IDE'
    route        : '/:name?/IDE'
    behavior     : 'application'
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn()
      failure    : (options, cb)->
        KD.getSingleton('appManager').open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()
    commands:
      'split vertically'   : 'splitVertically'
      'split horizontally' : 'splitHorizontally'
      'merge splitview'    : 'mergeSplitView'
      'create new file'    : 'createNewFile'
      'collapse sidebar'   : 'collapseSidebar'
      'expand sidebar'     : 'expandSidebar'
    keyBindings: [
      { command: 'split vertically',   binding: 'ctrl+alt+v', global: yes }
      { command: 'split horizontally', binding: 'ctrl+alt+h', global: yes }
      { command: 'merge splitview',    binding: 'ctrl+alt+m', global: yes }
      { command: 'create new file',    binding: 'ctrl+alt+n', global: yes }
      { command: 'collapse sidebar',   binding: 'ctrl+alt+c', global: yes }
      { command: 'expand sidebar',     binding: 'ctrl+alt+e', global: yes }
    ]

  constructor: (options = {}, data) ->
    $('body').addClass 'dark'

    options.appInfo =
      type          : 'application'
      name          : 'IDE'

    super options, data

    layoutOptions   =
      direction     : 'vertical'
      splitName     : 'BaseSplit'
      sizes         : [ '234px', null ]
      views         : [
        {
          type      : 'custom'
          name      : 'filesPane'
          paneClass : IDEFilesTabView
        },
        {
          type      : 'custom'
          name      : 'editorPane'
          paneClass : IDEView
        }
      ]

    appView   = @getView()
    workspace = @workspace = new Workspace { layoutOptions }
    @ideViews = []

    workspace.once 'ready', =>
      panel = workspace.getView()
      appView.addSubView panel

      panel.once 'viewAppended', =>
        ideView = panel.getPaneByName 'editorPane'
        @setActiveTabView ideView.tabView
        @ideViews.push ideView

        splitView = panel.layout.getSplitViewByName 'BaseSplit'
        splitView.on 'ResizeDidStop', @bound 'handleResize'

        appView.emit 'KeyViewIsSet'

  setActiveTabView: (tabView) ->
    @activeTabView = tabView

  splitTabView: (type = 'vertical') ->
    ideView        = @activeTabView.parent
    ideParent      = ideView.parent
    newIDEView     = new IDEView
    @activeTabView = null

    ideView.detach()

    splitView   = new KDSplitView
      type      : type
      views     : [ null, newIDEView ]

    @ideViews.push newIDEView

    splitView.once 'viewAppended', ->
      splitView.panels.first.attach ideView
      splitView.panels[0] = ideView.parent
      splitView.options.views[0] = ideView

    ideParent.addSubView splitView
    @setActiveTabView newIDEView.tabView

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
    ideView = new IDEView
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
    @ideViews.push ideView

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

    splitView.once 'PanelSetToFloating', ->
      floatedPanel._lastSize = desiredSize

    splitView.setFloatingPanel 0, 39
    tabView.showPaneByName 'Dummy'

    tabView.on 'PaneDidShow', ->
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

  updateSettings: (component, key, value) ->
    Class  = if component is 'editor' then EditorPane else TerminalPane
    method = "set#{key.capitalize()}"

    for ideView in @ideViews
      for pane in ideView.tabView.panes
        view = pane.getSubViews().first
        if view instanceof Class
          if component is 'editor'
            view.aceView.ace[method] value
          else
            view.webtermView.updateSettings()

  handleResize: ->
    # TODO: C/P from update settings, should make a common helper method
    for ideView in @ideViews
      for pane in ideView.tabView.panes
        view = pane.getSubViews().first
        if view instanceof EditorPane
          view.aceView.ace.setHeight view.getHeight() - 23
          view.aceView.ace.editor.resize yes
