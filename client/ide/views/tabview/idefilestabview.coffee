class IDEFilesTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.cssClass      = 'ide-files-tab'
    options.addPlusHandle = no

    super options, data

    @createFilesPane()
    @createVMsPane()
    @createSettingsPane()

    # temp hack to fix collapsed panel tab change bug
    dummyPane  = new KDTabPaneView
      name     : 'Dummy'
      closable : no

    @tabView.addPane dummyPane

    @tabView.showPaneByIndex 0

  createFilesPane: ->
    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    @finderPane = new FinderPane
    filesPane.addSubView @finderPane

    @tabView.addPane filesPane

  createVMsPane: ->
    vmsPane    = new KDTabPaneView
      name     : 'VMs'
      closable : no

    vmsPane.addSubView new VMListPane
    @tabView.addPane  vmsPane

    @on 'VMMountRequested', (vmData) =>
      @finderPane.emit 'VMMountRequested', vmData

    @on 'VMUnmountRequested', (vmData) =>
      @finderPane.emit 'VMUnmountRequested', vmData

  createSettingsPane: ->
    settingsPane = new KDTabPaneView
      name       : 'Settings'
      closable   : no

    settingsPane.addSubView new SettingsPane
    @tabView.addPane settingsPane
