class IDE.IDEFilesTabView extends IDE.WorkspaceTabView

  constructor: (options = {}, data) ->

    options.cssClass      = 'ide-files-tab'
    options.addPlusHandle = no

    super options, data

    @createFilesPane()
    @createSettingsPane()

    # temp hack to fix collapsed panel tab change bug
    dummyPane  = new KDTabPaneView
      name     : 'Dummy'
      closable : no

    @tabView.addPane dummyPane

    @tabView.showPaneByIndex 0

    @tabView.tabHandleContainer.tabs.addSubView @toggle = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'toggle'
      click    : @bound 'createToggleMenu'

    @tabView.tabHandleContainer.tabs.addSubView @logo = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'kd-logo'
      click    : -> KD.singletons.mainView.toggleSidebar()

  createFilesPane: ->
    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    @finderPane = new IDE.FinderPane
    filesPane.addSubView @finderPane

    @tabView.addPane filesPane

    @on 'MachineMountRequested', (machineData, rootPath) =>
      @finderPane.emit 'MachineMountRequested', machineData, rootPath

    @on 'MachineUnmountRequested', (machineData) =>
      @finderPane.emit 'MachineUnmountRequested', machineData

  createSettingsPane: ->
    settingsPane = new KDTabPaneView
      name       : 'Settings'
      closable   : no

    settingsPane.addSubView new IDE.SettingsPane
    @tabView.addPane settingsPane


  createToggleMenu: ->

    options =
      menuWidth: 180
      x: @toggle.getX()
      y: @toggle.getY() + 20

    {appManager, mainView} = KD.singletons
    ideApp = appManager.getFrontApp()

    ideSidebarState    = if ideApp.isSidebarCollapsed then 'Expand' else 'Collapse'
    kodingSidebarState = if mainView.isCollapsed      then 'Expand' else 'Collapse'

    items = {}

    items["#{ideSidebarState} IDE sidebar"] =
      callback: =>
        appManager.tell 'IDE', 'toggleSidebar'
        @contextMenu.destroy()

    items["#{kodingSidebarState} Koding sidebar"] =
      callback: =>
        mainView.toggleSidebar()
        @contextMenu.destroy()

    @contextMenu = new KDContextMenu options, items
