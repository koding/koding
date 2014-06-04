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

    workspace = @workspace = new Workspace { layoutOptions }
    workspace.once 'ready', =>
      panel = workspace.getView()
      @getView().addSubView panel

      panel.once 'viewAppended', =>
        @setActiveTabView panel.getPaneByName('editorPane').tabView

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
    desiredSize  = 289

    splitView.once 'PanelSetToFloating', ->
      floatedPanel._lastSize = desiredSize

    splitView.setFloatingPanel 0, 39

    filesPane.tabView.on 'PaneDidShow', ->
      splitView.showPanel 0
      floatedPanel._lastSize = desiredSize

    floatedPanel.on 'ReceivedClickElsewhere', ->
      KD.utils.defer ->
        splitView.setFloatingPanel 0, 39

  expandSidebar: ->
    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first

    floatedPanel._lastSize = 250
    splitView.unsetFloatingPanel 0
    floatedPanel.off 'ReceivedClickElsewhere'
