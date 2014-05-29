class IDEFilesTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.cssClass      = 'ide-files-tab'
    options.addPlusHandle = no

    super options, data

    ideAppController = KD.getSingleton('appManager').getFrontApp()

    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    filesPane.addSubView new FinderPane
    @tabView.addPane filesPane

    vmsPane    = new KDTabPaneView
      name     : 'VMs'
      closable : no

    vmsPane.addSubView new VMListPane
    @tabView.addPane  vmsPane

    settingsPane = new KDTabPaneView
      name       : 'Settings'
      closable   : no

    settingsPane.addSubView new SettingsPane
    @tabView.addPane settingsPane


    ################################
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

    actionsPane.addSubView new KDButtonView
      title      : 'Collapse sidebar'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.collapseSidebar()

    actionsPane.addSubView new KDButtonView
      title      : 'Expand sidebar'
      cssClass   : 'compact solid green'
      attributes :
        style    : 'display: block; margin: 20px; width: 200px; '
      callback   : -> ideAppController.expandSidebar()

    @tabView.addPane actionsPane
