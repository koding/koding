FinderPane       = require '../../workspace/panes/finderpane'
SettingsPane     = require '../../workspace/panes/settings/settingspane'
WorkspaceTabView = require '../../workspace/workspacetabview'


class IDEFilesTabView extends WorkspaceTabView

  constructor: (options = {}, data) ->

    options.cssClass      = 'ide-files-tab'
    options.addPlusHandle = no

    super options, data

    @createFilesPane()
    @createSettingsPane()
    @createKodingSidebarHandle()

    # temp hack to fix collapsed panel tab change bug
    dummyPane  = new KDTabPaneView
      name     : 'Dummy'
      closable : no

    @tabView.handles.forEach (handle) =>
      handle.on 'mousedown', => @emit 'TabHandleMousedown'

    @tabView.addPane dummyPane

    @tabView.showPaneByIndex 0

    # @tabView.tabHandleContainer.tabs.addSubView @toggle = new KDCustomHTMLView
    #   tagName  : 'span'
    #   cssClass : 'toggle'
    #   click    : @bound 'createToggleMenu'

    @tabView.tabHandleContainer.tabs.addSubView @logo = new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'kd-logo'
      click    : -> KD.singletons.mainView.toggleSidebar()


  createFilesPane: ->

    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    @finderPane = new FinderPane
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

    settingsPane.addSubView @settingsPane = new SettingsPane
    @tabView.addPane settingsPane


  # createToggleMenu: ->

  #   options =
  #     menuWidth: 180
  #     x: @toggle.getX()
  #     y: @toggle.getY() + 20

  #   {appManager, mainView} = KD.singletons
  #   ideApp = appManager.getFrontApp()
  #   isKodingSidebarCollapsed = mainView.isSidebarCollapsed

  #   ideSidebarStateText    = if ideApp.isSidebarCollapsed then 'Expand' else 'Collapse'
  #   kodingSidebarStateText = if isKodingSidebarCollapsed  then 'Expand' else 'Collapse'

  #   items = {}

  #   items["#{ideSidebarStateText} IDE sidebar"] =
  #     callback: =>
  #       appManager.tell 'IDE', 'toggleSidebar'
  #       @contextMenu.destroy()

  #   items["#{kodingSidebarStateText} Koding sidebar"] =
  #     callback: =>
  #       mainView.toggleSidebar()
  #       ideApp.isKodingSidebarCollapsed = !isKodingSidebarCollapsed
  #       @contextMenu.destroy()

  #   @contextMenu = new KDContextMenu options, items

  createKodingSidebarHandle: ->

    { mainView } = KD.singletons

    handle       = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'koding-sidebar-handle'
      attributes : alt: 'Double-click to toggle main sidebar'
      dblclick   : (event) ->
        KD.utils.stopDOMEvent event
        mainView.toggleSidebar()
        KD.utils.wait 233, ->
          KD.singletons.windowController.notifyWindowResizeListeners()

    @tabView.addSubView handle


module.exports = IDEFilesTabView
