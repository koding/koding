ndpane                        = require 'ndpane'
_                             = require 'lodash'
kd                            = require 'kd'
$                             = require 'jquery'
kookies                       = require 'kookies'

KDBlockingModalView           = kd.BlockingModalView
KDCustomHTMLView              = kd.CustomHTMLView
KDModalView                   = kd.ModalView
KDNotificationView            = kd.NotificationView
KDSplitView                   = kd.SplitView
KDSplitViewPanel              = kd.SplitViewPanel
remote                        = require('app/remote').getInstance()
globals                       = require 'globals'
nick                          = require 'app/util/nick'
showError                     = require 'app/util/showError'
whoami                        = require 'app/util/whoami'
Machine                       = require 'app/providers/machine'
KodingKontrol                 = require 'app/kite/kodingkontrol'
FSHelper                      = require 'app/util/fs/fshelper'
AppController                 = require 'app/appcontroller'
CollaborationController       = require './collaborationcontroller'
VideoCollaborationController  = require './videocollaborationcontroller'
IDEContentSearch              = require './views/contentsearch/idecontentsearch'
IDEEditorPane                 = require './workspace/panes/ideeditorpane'
IDEFileFinder                 = require './views/filefinder/idefilefinder'
IDEFilesTabView               = require './views/tabview/idefilestabview'
IDEShortcutsView              = require './views/shortcutsview/ideshortcutsview'
IDEStatusBar                  = require './views/statusbar/idestatusbar'
IDEStatusBarMenu              = require './views/statusbar/idestatusbarmenu'
IDETerminalPane               = require './workspace/panes/ideterminalpane'
IDEView                       = require './views/tabview/ideview'
IDEWorkspace                  = require './workspace/ideworkspace'
splashMarkups                 = require './util/splashmarkups'
IDEApplicationTabView         = require './views/tabview/ideapplicationtabview'
AceFindAndReplaceView         = require 'ace/acefindandreplaceview'
EnvironmentsMachineStateModal = require 'app/providers/environmentsmachinestatemodal'
environmentDataProvider       = require 'app/userenvironmentdataprovider'

require('./routes')()


module.exports =

class IDEAppController extends AppController

  _.extend @prototype, CollaborationController
  _.extend @prototype, VideoCollaborationController

  {
    Stopped, Running, NotInitialized, Terminated, Unknown, Pending,
    Starting, Building, Stopping, Rebooting, Terminating, Updating
  } = Machine.State

  {noop, warn} = kd

  @options = require './ideappcontrolleroptions'

  constructor: (options = {}, data) ->
    options.appInfo =
      type          : 'application'
      name          : 'IDE'

    super options, data

    layoutOptions     =
      splitOptions    :
        direction     : 'vertical'
        name          : 'BaseSplit'
        sizes         : [ 250, null ]
        maximums      : [ 400, null ]
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

    $('body').addClass 'dark' # for theming

    @workspace = new IDEWorkspace { layoutOptions }
    @ideViews  = []

    # todo:
    # - following two should be abstracted out into a separate api
    @layout = ndpane(16)
    @layoutMap = new Array(16*16)

    {windowController} = kd.singletons
    windowController.addFocusListener @bound 'setActivePaneFocus'

    @workspace.once 'ready', => @getView().addSubView @workspace.getView()

    kd.singletons.appManager.on 'AppIsBeingShown', (app) =>

      return  unless app instanceof IDEAppController

      @setActivePaneFocus on

      # Temporary fix for IDE is not shown after
      # opening pages which uses old SplitView.
      # TODO: This needs to be fixed. ~Umut
      kd.singletons.windowController.notifyWindowResizeListeners()

      @resizeActiveTerminalPane()


  prepareIDE: (withFakeViews = no) ->

    panel     = @workspace.getView()
    appView   = @getView()
    ideView   = panel.getPaneByName 'editorPane'

    @setActiveTabView ideView.tabView
    @registerIDEView  ideView

    splitViewPanel = ideView.parent.parent
    @createStatusBar splitViewPanel
    @createFindAndReplaceView splitViewPanel

    appView.emit 'KeyViewIsSet'

    @createInitialView withFakeViews
    @bindCollapseEvents()

    {@finderPane, @settingsPane} = @workspace.panel.getPaneByName 'filesPane'

    @bindRouteHandler()
    @initiateAutoSave()
    @emit 'ready'


  bindRouteHandler: ->

    {router, mainView} = kd.singletons

    router.on 'RouteInfoHandled', (routeInfo) =>
      if routeInfo.path.indexOf('/IDE') is -1
        if mainView.isSidebarCollapsed
          mainView.toggleSidebar()


  bindCollapseEvents: ->

    { panel } = @workspace

    filesPane = @workspace.panel.getPaneByName 'filesPane'

    # We want double click to work
    # if only the sidebar is collapsed. ~Umut
    expand = (event) =>
      kd.utils.stopDOMEvent event  if event?
      @toggleSidebar()  if @isSidebarCollapsed

    filesPane.on 'TabHandleMousedown', expand

    baseSplit = panel.layout.getSplitViewByName 'BaseSplit'
    baseSplit.resizer.on 'dblclick', @bound 'toggleSidebar'


  setActiveTabView: (tabView) ->

    return  if tabView is @activeTabView
    @setActivePaneFocus off
    @activeTabView = tabView
    @setActivePaneFocus on


  setActivePaneFocus: (state) ->

    return  unless pane = @getActivePaneView()
    return  if pane is @activePaneView

    @activePaneView = pane

    kd.utils.defer -> pane.setFocus? state


  splitTabView: (type = 'vertical', ideViewOptions) ->

    ideView        = @activeTabView.parent
    ideParent      = ideView.parent
    newIDEView     = new IDEView ideViewOptions

    splitViewPanel = @activeTabView.parent.parent
    if splitViewPanel instanceof KDSplitViewPanel
    then layout = splitViewPanel._layout
    else layout = @layout

    @activeTabView = null

    ideView.detach()

    splitView   = new KDSplitView
      type      : type
      views     : [ null, newIDEView ]

    layout.split(type is 'vertical')
    splitView._layout = layout

    @registerIDEView newIDEView

    splitView.once 'viewAppended', =>
      splitView.panels.first.attach ideView
      splitView.panels[0] = ideView.parent
      splitView.options.views[0] = ideView
      splitView.panels.forEach (panel, i) =>
        leaf = layout.leafs[i]
        panel._layout = leaf
        @layoutMap[leaf.data.offset] = panel

    ideParent.addSubView splitView
    @setActiveTabView newIDEView.tabView

    splitView.on 'ResizeDidStop', kd.utils.throttle 500, @bound 'doResize'


  mergeSplitView: ->

    panel     = @activeTabView.parent.parent
    splitView = panel.parent
    {parent}  = splitView

    return  unless panel instanceof KDSplitViewPanel

    if parent instanceof KDSplitViewPanel
      parentSplitView    = parent.parent
      panelIndexInParent = parentSplitView.panels.indexOf parent

    splitView.once 'SplitIsBeingMerged', (views) =>
      for view in views
        index = @ideViews.indexOf view
        @ideViews.splice index, 1

      @layoutMap[splitView._layout.data.offset] = parent

      @handleSplitMerge views, parent, parentSplitView, panelIndexInParent
      @doResize()

    splitView._layout.leafs.forEach (leaf) =>
      @layoutMap[leaf.data.offset] = null
    splitView._layout.merge()

    splitView.merge()


  handleSplitMerge: (views, container, parentSplitView, panelIndexInParent) ->

    ideView = new IDEView createNewEditor: no
    panes   = []

    for view in views
      {tabView} = view

      for p in tabView.panes by -1
        {pane} = tabView.removePane p, yes, (yes if tabView instanceof IDEApplicationTabView)
        panes.push pane

      view.destroy()

    container.addSubView ideView

    for pane in panes
      ideView.tabView.addPane pane

    @setActiveTabView ideView.tabView
    @registerIDEView ideView

    if parentSplitView and panelIndexInParent
      parentSplitView.options.views[panelIndexInParent] = ideView
      parentSplitView.panels[panelIndexInParent]        = ideView.parent


  openFile: (file, contents, callback = noop, emitChange) ->

    kallback = (pane) =>
      @emit 'EditorPaneDidOpen', pane  if pane?.options.paneType is 'editor'
      callback pane

    @activeTabView.emit 'FileNeedsToBeOpened', file, contents, kallback, emitChange


  openMachineTerminal: (machineData) ->

    @activeTabView.emit 'MachineTerminalRequested', machineData


  openMachineWebPage: (machineData) ->

    @activeTabView.emit 'MachineWebPageRequested', machineData


  mountMachine: (machineData) ->

    # interrupt if workspace was changed
    return if machineData.uid isnt @workspaceData.machineUId

    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'

    path = @workspaceData?.rootPath

    path ?= if owner = machineData.getOwner()
    then "/home/#{owner}"
    else '/'

    @workspace.ready ->
      filesPane.emit 'MachineMountRequested', machineData, path


  unmountMachine: (machineData) ->

    panel     = @workspace.getView()
    filesPane = panel.getPaneByName 'filesPane'

    filesPane.emit 'MachineUnmountRequested', machineData


  isMachineRunning: ->

    return @mountedMachine.status.state is Running


  createInitialView: (withFakeViews) ->

    kd.utils.defer =>
      @splitTabView 'horizontal', createNewEditor: no
      @getMountedMachine (err, machine) =>

        return unless machine

        machine = new Machine { machine }  unless machine instanceof Machine

        for ideView in @ideViews
          ideView.mountedMachine = @mountedMachine

        if not @isMachineRunning() or withFakeViews
          nickname     = machine.getOwner()
          machineLabel = machine.slug or machine.label
          splashes     = splashMarkups

          @fakeEditor       = @ideViews.first.createEditor()
          @fakeTabView      = @activeTabView
          fakeTerminalView  = new KDCustomHTMLView partial: splashes.getTerminal nickname
          @fakeTerminalPane = @fakeTabView.parent.createPane_ fakeTerminalView, { name: 'Terminal' }
          @fakeFinderView   = new KDCustomHTMLView partial: splashes.getFileTree nickname, machineLabel

          @finderPane.addSubView @fakeFinderView, '.nfinder .jtreeview-wrapper'
          @fakeEditor.once 'EditorIsReady', => kd.utils.defer => @fakeEditor.setFocus no

        else

          @fetchSnapshot (snapshot)=>
            return @resurrectLocalSnapshot snapshot  if snapshot

            @ideViews.first.createEditor()
            @ideViews.last.createTerminal { machine }
            @setActiveTabView @ideViews.first.tabView
            @forEachSubViewInIDEViews_ (pane) ->
              pane.isInitial = yes


  setMountedMachine: (machine) ->

    @mountedMachine = machine
    @emit 'MachineDidMount', machine, @workspaceData


  whenMachineReady: (callback) ->

    if @mountedMachine
    then callback @mountedMachine, @workspaceData
    else @once 'MachineDidMount', callback


  getMountedMachine: (callback = noop) ->

    return callback()  unless @mountedMachineUId

    kd.utils.defer =>
      environmentDataProvider.fetchMachineByUId @mountedMachineUId, (machine, ws) =>
        machine = new Machine { machine }  unless machine instanceof Machine
        @setMountedMachine machine

        callback null, machine


  mountMachineByMachineUId: (machineUId) ->

    return  if @mountedMachine

    computeController = kd.getSingleton 'computeController'
    container         = @getView()
    withFakeViews     = no

    environmentDataProvider.fetchMachineByUId machineUId, (machineItem) =>

      unless machineItem
        return @createMachineStateModal { state: 'NotFound', container }

      unless machineItem instanceof Machine
        machineItem = new Machine machine: machineItem

      if not machineItem.isMine() and not machineItem.isApproved()
        { activitySidebar } = kd.singletons.mainView
        box = activitySidebar.getMachineBoxByMachineUId machineItem.uid
        box.machineItem.showSidebarSharePopup sticky: yes
        withFakeViews = yes

      @setMountedMachine machineItem

      @prepareIDE withFakeViews

      return no  if withFakeViews

      if machineItem
        {state}         = machineItem.status
        machineId       = machineItem._id
        baseMachineKite = machineItem.getBaseKite()
        isKiteConnected = baseMachineKite._state is 1


        if state is Running and isKiteConnected
          @mountMachine machineItem
          baseMachineKite.fetchTerminalSessions()
          @prepareCollaboration()

        else
          unless @machineStateModal

            @createMachineStateModal {
              state, container, machineItem, initial: yes
            }

            if state is NotInitialized
              @setupFakeActivityNotification()

          @once 'IDEReady', => @prepareCollaboration()

        @bindMachineEvents machineItem

      else
        @createMachineStateModal { state: 'NotFound', container }


  bindMachineEvents: (machineItem) ->

    actionRequiredStates = [Pending, Stopping, Stopped, Terminating, Terminated]

    kd.getSingleton 'computeController'

      .on "public-#{machineItem._id}", (event) =>

        if event.status in actionRequiredStates
          @showStateMachineModal machineItem, event

        switch event.status
          when Terminated then @handleMachineTerminated()

      .on "reinit-#{machineItem._id}", @bound 'handleMachineReinit'


  handleMachineTerminated: ->

    @once 'IDEDidQuit', @bound 'removeWorkspaceSnapshot'


  handleMachineReinit: ({status}) ->

    switch status
      when 'Building'
        environmentDataProvider.ensureDefaultWorkspace kd.noop
      when 'Running'
        @once 'IDEDidQuit', @bound 'removeWorkspaceSnapshot'
        @quit()


  showStateMachineModal: (machineItem, event) ->

    KodingKontrol.dcNotification?.destroy()
    KodingKontrol.dcNotification = null

    machineItem.getBaseKite( no ).disconnect()

    if @machineStateModal
      @machineStateModal.updateStatus event
    else
      {state}   = machineItem.status
      container = @getView()
      @createMachineStateModal { state, container, machineItem }


  createMachineStateModal: (options = {}) ->

    { mainView } = kd.singletons
    mainView.toggleSidebar()  if mainView.isSidebarCollapsed

    { state, container, machineItem, initial } = options

    container   ?= @getView()
    modalOptions = { state, container, initial }
    @machineStateModal = new EnvironmentsMachineStateModal modalOptions, machineItem

    @machineStateModal.once 'KDObjectWillBeDestroyed', => @machineStateModal = null
    @machineStateModal.once 'IDEBecameReady',          => @handleIDEBecameReady machineItem


  collapseSidebar: ->

    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first
    filesPane    = panel.getPaneByName 'filesPane'
    {tabView}    = filesPane
    desiredSize  = 250

    splitView.resizePanel 39, 0
    @getView().setClass 'sidebar-collapsed'
    floatedPanel.setClass 'floating'
    @activeFilesPaneName = tabView.activePane.name
    tabView.showPaneByName 'Dummy'

    @isSidebarCollapsed = yes

    tabView.on 'PaneDidShow', (pane) ->
      return if pane.options.name is 'Dummy'
      @expandSidebar()  if @isSidebarCollapsed


  expandSidebar: ->

    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first
    filesPane    = panel.getPaneByName 'filesPane'

    splitView.resizePanel 250, 0
    @getView().unsetClass 'sidebar-collapsed'
    floatedPanel.unsetClass 'floating'
    @isSidebarCollapsed = no
    filesPane.tabView.showPaneByName @activeFilesPaneName


  toggleSidebar: ->

    if @isSidebarCollapsed then @expandSidebar() else @collapseSidebar()


  splitVertically: ->

    @splitTabView 'vertical'


  splitHorizontally: ->

    @splitTabView 'horizontal'

  createNewFile: do ->
    newFileSeed = 1

    return ->
      path     = "localfile:/Untitled-#{newFileSeed++}.txt@#{Date.now()}"
      file     = FSHelper.createFileInstance { path, machine: @mountedMachine }
      contents = ''

      @openFile file, contents


  createNewTerminal: (options={}) ->

    { machine, path, resurrectSessions } = options

    machine = @mountedMachine  unless machine instanceof Machine

    if @workspaceData and not path
      { rootPath, isDefault } = @workspaceData
      options.path = rootPath  if rootPath and not isDefault

    @activeTabView.emit 'TerminalPaneRequested', options


  createNewBrowser: (url) ->

    url = ''  unless typeof url is 'string'

    @activeTabView.emit 'PreviewPaneRequested', url


  createNewDrawing: (paneHash) ->

    paneHash = null unless typeof paneHash is 'string'

    @activeTabView.emit 'DrawingPaneRequested', paneHash


  moveTab: (direction) ->

    tabView = @activeTabView
    return unless tabView.parent?

    panel = tabView.parent.parent
    return  unless panel instanceof KDSplitViewPanel

    targetOffset = @layout[direction](panel._layout.data.offset)
    return  unless targetOffset?

    targetPanel = @layoutMap[targetOffset]

    {pane} = tabView.removePane tabView.getActivePane(), yes, yes

    targetPanel.subViews.first.tabView.addPane pane
    @setActiveTabView targetPanel.subViews.first.tabView
    @doResize()


  moveTabUp: -> @moveTab 'north'

  moveTabDown: -> @moveTab 'south'

  moveTabLeft: -> @moveTab 'west'

  moveTabRight: -> @moveTab 'east'


  goToLeftTab: ->

    index = @activeTabView.getActivePaneIndex()
    return if index is 0

    @activeTabView.showPaneByIndex index - 1


  goToRightTab: ->

    index = @activeTabView.getActivePaneIndex()
    return if index is @activeTabView.length - 1

    @activeTabView.showPaneByIndex index + 1


  goToTabNumber: (index) ->

    @activeTabView.showPaneByIndex index


  goToLine: ->

    @activeTabView.emit 'GoToLineRequested'


  closeTab: ->

    @activeTabView.removePane @activeTabView.getActivePane()


  registerIDEView: (ideView) ->

    @ideViews.push ideView
    ideView.mountedMachine = @mountedMachine

    ideView.on 'PaneRemoved', (pane) =>
      ideViewLength  = 0
      ideViewLength += ideView.tabView.panes.length  for ideView in @ideViews
      delete @generatedPanes[pane.view.hash]

      if session = pane.view.remote?.session
        @mountedMachine.getBaseKite().removeFromActiveSessions session

      @statusBar.showInformation()  if ideViewLength is 0
      @writeSnapshot()

    ideView.tabView.on 'PaneAdded', (pane) =>
      @registerPane pane
      @writeSnapshot()

    ideView.on 'ChangeHappened', (change) =>
      @syncChange change  if @rtm

    ideView.on 'UpdateWorkspaceSnapshot', =>
      @writeSnapshot()


  writeSnapshot: ->

    return  if @isDestroyed or not @isMachineRunning()

    name  = @getWorkspaceSnapshotName()
    value = @getWorkspaceSnapshot()

    @mountedMachine.getBaseKite().storageSetQueued name, value


  removeWorkspaceSnapshot: ->

    @mountedMachine.getBaseKite().storageDelete @getWorkspaceSnapshotName()


  getWorkspaceSnapshotName: ->

    return "wss.#{@workspaceData.slug}"


  registerPane: (pane) ->

    {view} = pane
    unless view?.hash?
      return warn 'view.hash not found, returning'

    @generatedPanes or= {}
    @generatedPanes[view.hash] = yes

    view.on 'ChangeHappened', (change) =>
      @syncChange change  if @rtm


  forEachSubViewInIDEViews_: (callback = noop, paneType) ->

    if typeof callback is 'string'
      [paneType, callback] = [callback, paneType]

    for ideView in @ideViews
      for pane in ideView.tabView.panes when pane
        return  unless view = pane.getSubViews().first
        if paneType
        then callback view  if view.getOptions().paneType is paneType
        else callback view


  updateSettings: (component, key, value) ->

    # TODO: Refactor this method by passing component type to helper method.
    Class  = if component is 'editor' then IDEEditorPane else IDETerminalPane
    method = "set#{key.capitalize()}"

    if key is 'useAutosave' # autosave is special case, handled by app manager.
      return if value then @enableAutoSave() else @disableAutoSave()

    @forEachSubViewInIDEViews_ (view) ->
      if view instanceof Class
        if component is 'editor'
          view.aceView.ace[method]? value
        else
          view.webtermView.updateSettings()


  initiateAutoSave: ->

    {editorSettingsView} = @settingsPane

    editorSettingsView.on 'SettingsFetched', =>
      @enableAutoSave()  if editorSettingsView.settings.useAutosave


  enableAutoSave: ->

    @autoSaveInterval = kd.utils.repeat 1000, =>
      @forEachSubViewInIDEViews_ 'editor', (ep) => ep.handleAutoSave()


  disableAutoSave: -> kd.utils.killRepeat @autoSaveInterval


  showShortcutsView: ->

    paneView = null

    @forEachSubViewInIDEViews_ (view) ->
      paneView = view.parent  if view instanceof IDEShortcutsView

    return paneView.parent.showPane paneView if paneView

    @activeTabView.emit 'ShortcutsViewRequested'


  getActivePaneView: ->

    return @activeTabView?.getActivePane()?.getSubViews().first


  saveFile: ->

    @getActivePaneView().emit 'SaveRequested'


  saveAs: ->

    @getActivePaneView().aceView.ace.requestSaveAs()


  saveAllFiles: ->

    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      {ace} = editorPane.aceView
      ace.once 'FileContentRestored', -> ace.removeModifiedFromTab()
      editorPane.emit 'SaveRequested'


  previewFile: ->

    view   = @getActivePaneView()
    {file} = view.getOptions()
    return unless file

    if FSHelper.isPublicPath file.path
      nickname    = @collaborationHost or nick()
      prefix      = "[#{@mountedMachineUId}]/home/#{nickname}/Web/"
      [temp, src] = file.path.split prefix
      @createNewBrowser "#{@mountedMachine.domain}/#{src}"
    else
      @notify 'File needs to be under ~/Web folder to preview.', 'error'


  updateStatusBar: (component, data) ->

    {status} = @statusBar

    text = if component is 'editor'
      {cursor, file} = data
      """
        <p class="line">#{++cursor.row}:#{++cursor.column}</p>
        <p>#{file.name}</p>
      """

    else if component is 'terminal' then "Terminal on #{data.machineName}"

    else if component is 'searchResult'
    then """Search results for #{data.searchText}"""

    else if typeof data is 'string' then data

    else ''

    status.updatePartial text


  showStatusBarMenu: (ideView, button) ->

    paneView = @getActivePaneView()
    paneType = paneView?.getOptions().paneType or null
    delegate = button
    menu     = new IDEStatusBarMenu { paneType, paneView, delegate }

    ideView.menu = menu

    menu.on 'viewAppended', ->
      if paneType is 'editor' and paneView
        {syntaxSelector} = menu
        {ace}            = paneView.aceView

        syntaxSelector.select.setValue ace.getSyntax() or 'text'
        syntaxSelector.on 'SelectionMade', (value) =>
          ace.setSyntax value


  showFileFinder: ->

    return @fileFinder.input.setFocus()  if @fileFinder

    @fileFinder = new IDEFileFinder
    @fileFinder.once 'KDObjectWillBeDestroyed', => @fileFinder = null


  showContentSearch: ->

    return @contentSearch.findInput.setFocus()  if @contentSearch

    @contentSearch = new IDEContentSearch
    @contentSearch.once 'KDObjectWillBeDestroyed', => @contentSearch = null
    @contentSearch.once 'ViewNeedsToBeShown', (view) =>
      @activeTabView.emit 'ViewNeedsToBeShown', view


  createStatusBar: (splitViewPanel) ->

    splitViewPanel.addSubView @statusBar = new IDEStatusBar


  createFindAndReplaceView: (splitViewPanel) ->

    splitViewPanel.addSubView @findAndReplaceView = new AceFindAndReplaceView
    @findAndReplaceView.hide()
    @findAndReplaceView.on 'FindAndReplaceViewClosed', =>
      @getActivePaneView().aceView?.ace.focus()
      @isFindAndReplaceViewVisible = no


  showFindReplaceView: (withReplaceMode) ->

    view = @findAndReplaceView
    @setFindAndReplaceViewDelegate()
    @isFindAndReplaceViewVisible = yes
    view.setViewHeight withReplaceMode
    view.setTextIntoFindInput '' # FIXME: Set selected text if exists

  showFindReplaceViewWithReplaceMode: -> @showFindReplaceView yes

  hideFindAndReplaceView: ->

    @findAndReplaceView.close no


  setFindAndReplaceViewDelegate: ->

    @findAndReplaceView.setDelegate @getActivePaneView()?.aceView or null


  showFindAndReplaceViewIfNecessary: ->

    if @isFindAndReplaceViewVisible
      @showFindReplaceView @findAndReplaceView.mode is 'replace'


  handleFileDeleted: (file) ->

    for ideView in @ideViews
      ideView.tabView.emit 'TabNeedsToBeClosed', file


  handleIDEBecameReady: (machine) ->

    {finderController} = @finderPane
    if @workspaceData
      finderController.updateMachineRoot @mountedMachine.uid, @workspaceData.rootPath
    else
      finderController.reset()

    machine.getBaseKite().fetchTerminalSessions()

    @fetchSnapshot (snapshot) =>

      unless @fakeViewsDestroyed
        @removeFakeViews()
        @fakeViewsDestroyed = yes

      if snapshot
        @resurrectLocalSnapshot snapshot  unless @isLocalSnapshotRestored
      else
        @addInitialViews()

      { mainView, onboardingController } = kd.singletons

      data = { machine, workspace: @workspaceData }
      mainView.activitySidebar.selectWorkspace data

      onboardingController.emit 'OnboardingRequested', 'IDE'

      @emit 'IDEReady'


  removeFakeViews: ->

    fakeEditorPane = @fakeEditor?.parent
    fakeEditorPane?.parent.removePane fakeEditorPane

    @fakeTerminalPane?.parent.removePane @fakeTerminalPane
    @fakeFinderView?.destroy()


  addInitialViews: ->

    @ideViews.first.createEditor()
    @ideViews.last.createTerminal machine: @mountedMachine
    @setActiveTabView @ideViews.first.tabView


  resurrectLocalSnapshot: (snapshot) ->

    resurrect = (snapshot)=>
      for key, value of snapshot when value
        @createPaneFromChange value, yes

      @isLocalSnapshotRestored = yes

    return  if snapshot then resurrect snapshot

    @fetchSnapshot (snapshot)->
      resurrect snapshot  if snapshot


  toggleFullscreenIDEView: ->

    @activeTabView.parent.toggleFullscreen()


  doResize: ->

    @forEachSubViewInIDEViews_ (pane) =>
      {paneType} = pane.options
      switch paneType
        when 'terminal'
          { webtermView } = pane
          { terminal }    = webtermView

          terminal.windowDidResize()  if terminal?

          {isActive} = @getActiveInstance()

          if not @isInSession and isActive
            kd.utils.wait 400, -> # defer was not enough.
              webtermView.triggerFitToWindow()

        when 'editor'
          height = pane.getHeight()
          {ace}  = pane.aceView

          if ace?.editor?
            ace.setHeight height
            ace.editor.resize()


  notify: (title, cssClass = 'success', type = 'mini', duration = 4000) ->

    return unless title
    new KDNotificationView { title, cssClass, type, duration }


  resizeActiveTerminalPane: ->

    for ideView in @ideViews
      pane = ideView.tabView.getActivePane()
      if pane and pane.view instanceof IDETerminalPane
        pane.view.webtermView.terminal?.updateSize()


  removePaneFromTabView: (pane, shouldDetach = no) ->

    paneView = pane.parent
    tabView  = paneView.parent
    tabView.removePane paneView


  getWorkspaceSnapshot: ->

    panes = {}

    @forEachSubViewInIDEViews_ (pane) ->
      return  unless pane
      return  if not pane.serialize or (@isInSession and pane.isInitial)

      data = pane.serialize()
      panes[data.hash] =
        type    : 'NewPaneCreated'
        context : data

    return panes


  changeActiveTabView: (paneType) ->

    if paneType is 'terminal'
      @setActiveTabView @ideViews.last.tabView
    else
      @setActiveTabView @ideViews.first.tabView


  syncChange: (change) ->

    {context} = change

    return  if not @rtm or not @rtm.isReady or not context

    {paneHash} = context
    nickname   = nick()

    if change.origin is nickname

      if context.paneType is 'editor'

        if change.type is 'NewPaneCreated'

          {content, path} = context.file

          string = @rtm.getFromModel path

          unless string
            @rtm.create 'string', path, content

        else if change.type is 'ContentChange'

          {content, path} = context.file
          string = @rtm.getFromModel path
          string.setText content  if string

        if context.file?.content
          delete context.file.content

      @changes.push change

    switch change.type

      when 'NewPaneCreated'
        @mySnapshot.set paneHash, change  if paneHash

      when 'PaneRemoved'
        @mySnapshot.delete paneHash  if paneHash


  handleChange: (change) ->

    {context, origin, type} = change

    return if not context or not origin or origin is nick()

    amIWatchingChangeOwner = @myWatchMap.keys().indexOf(origin) > -1

    mustSyncChanges = [ 'CursorActivity', 'FileSaved' ]

    if amIWatchingChangeOwner or type in mustSyncChanges
      targetPane = @getPaneByChange change

      if type is 'NewPaneCreated'
        @createPaneFromChange change

      else if type in ['TabChanged', 'PaneRemoved']
        paneView = targetPane?.parent
        tabView  = paneView?.parent
        ideView  = tabView?.parent

        return unless ideView

        ideView.suppressChangeHandlers = yes

        if type is 'TabChanged'
          tabView.showPane paneView
        else
          tabView.removePane paneView

        ideView.suppressChangeHandlers = no


      targetPane?.handleChange? change, @rtm


  getPaneByChange: (change) ->

    return unless change.context

    return @finderPane  if change.type is 'FileTreeInteraction'

    targetPane = null
    {context}  = change
    {paneType} = context

    @forEachSubViewInIDEViews_ paneType, (pane) =>

      if paneType is 'editor'
        if pane.getFile()?.path is context.file?.path
          targetPane = pane

      else
        targetPane = pane  if pane.hash is context.paneHash

    return targetPane


  createPaneFromChange: (change = {}, isFromLocalStorage) ->

    return  if not @rtm and not isFromLocalStorage

    { context } = change
    return  unless context

    paneHash = context.paneHash or context.hash
    currentSnapshot = @getWorkspaceSnapshot()

    return  if currentSnapshot[paneHash]

    { paneType } = context

    return  if not paneType or not paneHash

    @changeActiveTabView paneType

    switch paneType
      when 'terminal' then @createTerminalPaneFromChange change, paneHash
      when 'editor'   then @createEditorPaneFromChange change, paneHash
      when 'drawing'  then @createDrawingPaneFromChange change, paneHash

    if @mySnapshot and not @mySnapshot.get paneHash
      @mySnapshot.set paneHash, change


  createTerminalPaneFromChange: (change, hash) ->

    @createNewTerminal
      machine       : @mountedMachine
      session       : change.context.session
      hash          : hash
      joinUser      : @collaborationHost or nick()
      fitToWindow   : not @isInSession


  createEditorPaneFromChange: (change, hash) ->

    { context }        = change
    { file, paneType } = context
    { path }           = file
    options            = { path, machine : @mountedMachine }
    file               = FSHelper.createFileInstance options
    file.paneHash      = hash

    if @rtm?.realtimeDoc
      content = @rtm.getFromModel(path)?.getText() or ''
      @openFile file, content, noop, no

    else if file.isDummyFile()
      @openFile file, file.content, noop, no

    else
      file.fetchContents (err, contents = '') =>
        return showError err  if err
        @changeActiveTabView paneType
        @openFile file, contents, noop, no


  createDrawingPaneFromChange: (change, hash) ->

    @createNewDrawing hash


  showModal: (modalOptions = {}, callback = noop) ->
    return  if @modal

    modalOptions.overlay  ?= yes
    modalOptions.blocking ?= no
    modalOptions.buttons or=
      Yes        :
        cssClass : 'solid green medium'
        loader   : yes
        callback : callback
      No         :
        cssClass : 'solid light-gray medium'
        callback : => @modal.destroy()

    ModalClass = if modalOptions.blocking then KDBlockingModalView else KDModalView

    @modal = new ModalClass modalOptions
    @modal.once 'KDObjectWillBeDestroyed', =>
      delete @modal


  quit: ->

    @emit 'IDEWillQuit'

    @mountedMachine.getBaseKite(createIfNotExists = no).disconnect()

    kd.singletons.appManager.quit this

    kd.utils.defer ->
      kd.singletons.router.handleRoute '/IDE'

    @once 'KDObjectWillBeDestroyed', @lazyBound 'emit', 'IDEDidQuit'


  removeParticipantCursorWidget: (targetUser) ->

    @forEachSubViewInIDEViews_ 'editor', (editorPane) =>
      editorPane.removeParticipantCursorWidget targetUser


  makeReadOnly: ->

    return  if @isReadOnly

    @isReadOnly = yes
    ideView.isReadOnly = yes  for ideView in @ideViews
    @forEachSubViewInIDEViews_ (pane) -> pane.makeReadOnly()
    @finderPane.makeReadOnly()
    @getView().setClass 'read-only'


  makeEditable: ->

    return  unless @isReadOnly

    @isReadOnly = no
    ideView.isReadOnly = no  for ideView in @ideViews
    @forEachSubViewInIDEViews_ (pane) -> pane.makeEditable()
    @finderPane.makeEditable()
    @getView().unsetClass 'read-only'


  deleteWorkspaceRootFolder: (machineUId, rootPath) ->

    @finderPane.emit 'DeleteWorkspaceFiles', machineUId, rootPath


  getActiveInstance: ->

    {appControllers} = kd.singletons.appManager
    instance = appControllers.IDE.instances[appControllers.IDE.lastActiveIndex]

    return {instance, isActive: instance is this}


  handleShortcut: (e) ->

    kd.utils.stopDOMEvent e

    key = e.model.name

    switch key

      when 'findfilebyname'    then @showFileFinder()
      when 'searchallfiles'    then @showContentSearch()
      when 'splitvertically'   then @splitVertically()
      when 'splithorizontally' then @splitHorizontally()
      when 'mergesplitview'    then @mergeSplitView()
      when 'previewfile'       then @previewFile()
      when 'saveallfiles'      then @saveAllFiles()
      when 'createnewfile'     then @createNewFile()
      when 'createnewterminal' then @createNewTerminal()
      when 'createnewdrawing'  then @createNewDrawing()
      when 'togglesidebar'     then @toggleSidebar()
      when 'closetab'          then @closeTab()
      when 'gotolefttab'       then @goToLeftTab()
      when 'gotorighttab'      then @goToRightTab()
      when 'fullscreen'        then @toggleFullscreenIDEView()
      when 'movetabup'         then @moveTabUp()
      when 'movetabdown'       then @moveTabDown()
      when 'movetableft'       then @moveTabLeft()
      when 'movetabright'      then @moveTabRight()
      else
        if match = key.match /^gototabnumber(\d{1})$/
          # XXX: nope -og
          e.preventDefault()
          e.stopPropagation()

          @goToTabNumber parseInt(match[1], 10) - 1


  showUserRemovedModal: ->

    options        =
      title        : 'Machine access revoked'
      content      : 'Your access to this machine has been removed by its owner.'
      blocking     : yes
      buttons      :
        quit       :
          style    : 'solid light-gray medium'
          title    : 'OK'
          callback : =>

            @modal.destroy()
            @quit()

    @showModal options


  setupFakeActivityNotification: ->

    return  unless kookies.get('newRegister') is 'true'

    @machineStateModal?.once 'MachineTurnOnStarted', ->
      kookies.expire 'newRegister', path: '/'
      kd.getSingleton('mainView').activitySidebar.initiateFakeCounter()


  fetchSnapshot: (callback)->

    if not @mountedMachine or not @mountedMachine.isRunning()
      callback null
      return

    @mountedMachine.getBaseKite().storageGet @getWorkspaceSnapshotName()
    .then (snapshot)->
      callback snapshot
    .catch (err)->
      console.warn 'Failed to fetch snapshot', err
      callback null
