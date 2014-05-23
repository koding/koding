class IDEFilesTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.addPlusHandle = no

    super options, data

    ideAppController = KD.getSingleton('appManager').getFrontApp()

    dummyPane  = new KDTabPaneView
      name     : 'Actions'
      closable : no

    dummyPane.addSubView new KDButtonView
      title      : 'Vertical'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.splitTabView 'vertical'

    dummyPane.addSubView new KDButtonView
      title      : 'Horizontal'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.splitTabView 'horizontal'

    dummyPane.addSubView new KDButtonView
      title      : 'Merge'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.mergeSplitView()

    @tabView.addPane dummyPane

    ################################

    tabPane    = new KDTabPaneView
      name     : 'Files'
      closable : no

    tabPane.addSubView new FinderPane
    @tabView.addPane tabPane
