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
          paneClass : IDEView
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

    ideView        = @activeTabView.parent
    IDEParent      = ideView.parent
    newIDEView     = new IDEView
    @activeTabView = null

    ideView.detach()

    splitView   = new KDSplitView
      type      : type
      views     : [ null, newIDEView ]

    splitView.once 'viewAppended', ->
      splitView.panels.first.attach ideView
      splitView.options.views[0] = ideView

    IDEParent.addSubView splitView
    @setActiveTabView newIDEView.tabView

  mergeSplitView: ->
    splitView = @activeTabView.parent.parent.parent
    {parent} = splitView
    splitView.once 'SplitIsBeingMerged', (views) =>
      @handleSplitMerge views, parent

    splitView.merge()

  handleSplitMerge: (views, splitParent) ->
    ideView        = new IDEView
    @activeTabView = null

    # ideView.detach()

    panes   = []

    for view in views
      {tabView} = view
      for p in tabView.panes
        # pane.tabHandle.detach()
        {pane, handle} = tabView.removePane p, yes
        # ideView.tabView.addPane pane
        panes.push pane

      view.destroy()

    splitParent.addSubView ideView

    for pane in panes
      ideView.tabView.addPane pane

    @setActiveTabView ideView.tabView

  openFile: (file, contents) ->
    @activeTabView.openFile file, contents
