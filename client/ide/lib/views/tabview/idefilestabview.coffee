kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDTabPaneView = kd.TabPaneView
IDEFinderPane = require '../../workspace/panes/idefinderpane'
IDESettingsPane = require '../../workspace/panes/settings/idesettingspane'
IDEWorkspaceTabView = require '../../workspace/ideworkspacetabview'
OnboardingEvent = require 'app/onboarding/onboardingevent'


module.exports = class IDEFilesTabView extends IDEWorkspaceTabView

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
      click    : -> kd.singletons.mainView.toggleSidebar()


  createFilesPane: ->

    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    @finderPane = new IDEFinderPane
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

    settingsPane.addSubView @settingsPane = new IDESettingsPane
    @tabView.addPane settingsPane

    settingsPane.on 'KDTabPaneActive', ->
      kd.singletons.onboardingController.runOnboarding OnboardingEvent.IDESettingsOpened


  # createToggleMenu: ->

  #   options =
  #     menuWidth: 180
  #     x: @toggle.getX()
  #     y: @toggle.getY() + 20

  #   {appManager, mainView} = kd.singletons
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

    { mainView } = kd.singletons

    handle       = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'koding-sidebar-handle'
      attributes : alt: 'Double-click to toggle main sidebar'
      dblclick   : (event) ->
        kd.utils.stopDOMEvent event
        mainView.toggleSidebar()
        kd.utils.wait 233, ->
          kd.singletons.windowController.notifyWindowResizeListeners()

    @tabView.addSubView handle
