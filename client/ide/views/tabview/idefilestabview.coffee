class IDE.IDEFilesTabView extends IDE.WorkspaceTabView

  constructor: (options = {}, data) ->

    options.cssClass      = 'ide-files-tab'
    options.addPlusHandle = no

    super options, data

    @isCollapsed = no
    @createFilesPane()
    @createVMsPane()
    @createSettingsPane()

    # temp hack to fix collapsed panel tab change bug
    dummyPane  = new KDTabPaneView
      name     : 'Dummy'
      closable : no

    @tabView.addPane dummyPane

    @tabView.showPaneByIndex 0

    @tabView.tabHandleContainer.addSubView new KDCustomHTMLView
      tagName  : 'span'
      cssClass : 'toggle'
      click    : ->
        @toggleClass 'active'
        @isCollapsed = !@isCollapsed
        KD.getSingleton('appManager').tell 'IDE', 'toggleSidebar', @isCollapsed

  createFilesPane: ->
    filesPane  = new KDTabPaneView
      name     : 'Files'
      closable : no

    @finderPane = new IDE.FinderPane
    filesPane.addSubView @finderPane

    @tabView.addPane filesPane

  createVMsPane: ->
    vmsPane    = new KDTabPaneView
      name     : 'VMs'
      closable : no

    vmsPane.addSubView new IDE.VMListPane
    @tabView.addPane  vmsPane

    @on 'VMMountRequested', (vmData) =>
      @finderPane.emit 'VMMountRequested', vmData

    @on 'VMUnmountRequested', (vmData) =>
      @finderPane.emit 'VMUnmountRequested', vmData

  createSettingsPane: ->
    settingsPane = new KDTabPaneView
      name       : 'Settings'
      closable   : no

    settingsPane.addSubView new IDE.SettingsPane
    @tabView.addPane settingsPane
