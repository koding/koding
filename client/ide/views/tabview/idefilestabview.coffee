class IDEFilesTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.addPlusHandle = no

    super options, data

    ideAppController = KD.getSingleton('appManager').getFrontApp()

    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    filesPane.addSubView new FinderPane
    @tabView.addPane filesPane

    actionsPane  = new KDTabPaneView
      name     : 'Actions'
      closable : no

    actionsPane.addSubView new KDButtonView
      title      : 'Vertical'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.splitTabView 'vertical'

    actionsPane.addSubView new KDButtonView
      title      : 'Horizontal'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.splitTabView 'horizontal'

    actionsPane.addSubView new KDButtonView
      title      : 'Merge'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.mergeSplitView()

    actionsPane.addSubView new KDButtonView
      title      : 'New file'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.openFile()

    @tabView.addPane actionsPane
