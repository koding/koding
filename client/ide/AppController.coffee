class IDEAppController extends AppController

  KD.registerAppClass this,
    name         : 'IDE'
    route        : '/:name?/IDE'
    behavior     : 'application'
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn()
      failure    : (options, cb)->
        KD.singletons.appManager.open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()

  constructor: (options = {}, data) ->
    options.appInfo =
      type          : 'application'
      name          : 'IDE'

    super options, data

    layoutOptions   =
      direction     : 'vertical'
      splitName     : 'BaseSplit'
      sizes         : [ '250px', null ]
      views         : [
        {
          type      : 'custom'
          name      : 'filesPane'
          paneClass : IDEFilesTabView
        },
        {
          type      : 'custom'
          name      : 'editorPane'
          paneClass : IDETabView
        }
      ]

    workspace = @workspace = new Workspace { layoutOptions }
    workspace.once 'ready', =>
      panel = workspace.getView()
      @getView().addSubView panel

      panel.once 'viewAppended', =>
        @setActiveTabView panel.getPaneByName 'editorPane'

  setActiveTabView: (tabView) ->
    @activeTabView = tabView

  splitTabView: (type = 'vertical') ->

    IDEView        = @activeTabView.parent
    IDEParent      = IDEView.parent
    newIDEView     = new IDETabView
    @activeTabView = null

    IDEView.detach()

    splitView   = new KDSplitView
      type      : type
      views     : [ null, newIDEView ]

    splitView.once 'viewAppended', ->
      splitView.panels.first.attach IDEView
      splitView.options.views[0] = IDEView

    IDEParent.addSubView splitView
    @setActiveTabView newIDEView.tabView

  mergeSplitView: ->
    splitView = @activeTabView.parent.parent.parent
    {parent} = splitView
    splitView.once 'SplitIsBeingMerged', (views) =>
      @handleSplitMerge views, parent

    splitView.merge()

  handleSplitMerge: (views, splitParent) ->
    IDEView        = new IDETabView
    @activeTabView = null

    # IDEView.detach()

    panes = []

    for view in views
      {tabView} = view
      for p in tabView.panes
        # pane.tabHandle.detach()
        {pane, handle} = tabView.removePane pane, yes
        # IDEView.tabView.addPane pane
        panes.push p

      tabView.subViews = []
      view.destroy()

    splitParent.addSubView IDEView

    for pane in panes
      IDEView.tabView.addPane pane

    @setActiveTabView IDEView.tabView

  openFile: (file, contents) ->
    @activeTabView.openFile file, contents
