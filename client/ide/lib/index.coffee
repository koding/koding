debug                         = (require 'debug') 'ide'
_                             = require 'lodash'
kd                            = require 'kd'
nick                          = require 'app/util/nick'
ndpane                        = require 'ndpane'
remote                        = require 'app/remote'
actions                       = require 'app/flux/environment/actions'
kookies                       = require 'kookies'
Encoder                       = require 'htmlencode'
IDEView                       = require './views/tabview/ideview'
FSHelper                      = require 'app/util/fs/fshelper'
showError                     = require 'app/util/showError'
checkFlag                     = require 'app/util/checkFlag'
actionTypes                   = require 'app/flux/environment/actiontypes'
IDEWorkspace                  = require './workspace/ideworkspace'
IDEStatusBar                  = require './views/statusbar/idestatusbar'
AppController                 = require 'app/appcontroller'
IDEEditorPane                 = require './workspace/panes/ideeditorpane'
IDEFileFinder                 = require './views/filefinder/idefilefinder'
splashMarkups                 = require './util/splashmarkups'
IDEFilesTabView               = require './views/tabview/idefilestabview'
IDETerminalPane               = require './workspace/panes/ideterminalpane'
IDEStatusBarMenu              = require './views/statusbar/idestatusbarmenu'
IDEContentSearchView          = require './views/contentsearch/idecontentsearchview'
IDEApplicationTabView         = require './views/tabview/ideapplicationtabview'
AceFindAndReplaceView         = require 'ace/acefindandreplaceview'
CollaborationController       = require './collaborationcontroller'
ResourceStateModal            = require 'app/providers/resourcestatemodal'
KlientEventManager            = require 'app/kite/klienteventmanager'
IDELayoutManager              = require './workspace/idelayoutmanager'
StackAdminMessageController   = require './views/stacks/stackadminmessagecontroller'
ContentModal                  = require 'app/components/contentModal'
KDOverlayView                 = kd.OverlayView

NoStackFoundView = require 'app/nostackfoundview'

require('./routes').init()
require 'ide/styl'


module.exports = class IDEAppController extends AppController

  _.extend @prototype, CollaborationController

  NotInitialized = 'NotInitialized'  # Initial state, machine instance does not exists
  Building       = 'Building'        # Build started machine instance is being created...
  Starting       = 'Starting'        # Machine is booting...
  Running        = 'Running'         # Machine is physically running
  Stopping       = 'Stopping'        # Machine is turning off...
  Stopped        = 'Stopped'         # Machine is turned off
  Rebooting      = 'Rebooting'       # Machine is rebooting...
  Terminating    = 'Terminating'     # Machine is being destroyed...
  Terminated     = 'Terminated'      # Machine is destroyed, does not exist anymore
  Updating       = 'Updating'        # Machine is being updated by provisioner
  Unknown        = 'Unknown'         # Machine is in an unknown state

  { noop, warn } = kd

  INITIAL_BUILD_LOGS_TAIL_OFFSET = 15

  @options = require './ideappcontrolleroptions'

  constructor: (options = {}, data) ->

    options.view    = new kd.View { cssClass: 'dark' }
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

    @silent    = no
    @workspace = new IDEWorkspace { layoutOptions }
    @ideViews  = []
    @layout    = ndpane 16
    @layoutMap = new Array 16 * 16

    { windowController, appManager } = kd.singletons
    windowController.addFocusListener @bound 'handleWindowFocus'

    @layoutManager = new IDELayoutManager { delegate : this }

    @workspace.once 'ready', => @getView().addSubView @workspace.getView()

    kd.utils.defer =>
      debug 'IDE initialized', this

    appManager.on 'AppIsBeingShown', (app) =>

      return  unless app is this

      @setActivePaneFocus on, yes

      # Temporary fix for IDE is not shown after
      # opening pages which uses old SplitView.
      # TODO: This needs to be fixed. ~Umut
      windowController.notifyWindowResizeListeners()

      @runOnboarding()  if @isMachineRunning()

      unless @layoutManager.isSnapshotRestored()
        @layoutManager.restoreSnapshot()


  appIsShown: ->

    return  if @_listenersBound
    @_listenersBound = yes

    @on 'CloseFullScreen', =>
      [ideView] = @ideViews.filter (ideView) -> ideView.isFullScreen
      ideView.emit 'CloseFullScreen'  if ideView

    @on 'SnapshotUpdated', @bound 'saveLayoutSize'

    # FIXMEWS ~ GG
    kd.singletons.notificationController.on 'WorkspaceRemoved', (data) =>
      { machineUId, slug } = data

      if @mountedMachineUId is machineUId # and slug is @workspaceData.slug
        @quit()

    @layoutManager.once 'LayoutSizesApplied', @bound 'doResize'
    @on 'InstallationRequired', (command) => @createNewTerminal { command }

    kd.singletons.status.on 'reconnected', @bound 'bindKlientEvents'


  prepareIDE: (withFakeViews = no) ->

    panel     = @workspace.getView()
    appView   = @getView()

    ideView   = panel.getPaneByName 'editorPane'

    @setActiveTabView ideView.tabView
    @registerIDEView  ideView

    splitViewPanel = ideView.parent.parent
    @createStatusBar splitViewPanel
    @createFindAndReplaceView splitViewPanel
    @splitViewPanel = splitViewPanel

    appView.emit 'KeyViewIsSet'

    @createInitialView withFakeViews
    @bindCollapseEvents()

    { @finderPane, @settingsPane } = @workspace.panel.getPaneByName 'filesPane'

    @finderPane.on 'ChangeHappened', @bound 'syncChange'
    @finderPane.mountedMachine = @mountedMachine

    @initiateAutoSave()
    @emit 'ready'


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


  ###*
   * Listen for any `clientSubscribe` events that we care about.
   * Currently just `openFiles`, which triggers the IDE to open
   * a new file.
   *
   * @param {Machine} machine
  ###
  bindKlientEvents: (machine) ->

    kem = new KlientEventManager {}, machine

    if @klientOpenFilesSubscriberId?
      kem.unsubscribe 'openFiles', @klientOpenFilesSubscriberId

    kem
      .subscribe 'openFiles', @bound 'handleKlientOpenFiles'
      .then (res) =>
        { id } = res
        @klientOpenFilesSubscriberId = id
        return res


  handleWindowFocus: (state) ->

    return  unless global.document.contains @getView().getElement()

    @setActivePaneFocus state

    activePane = @getActivePaneView()

    activePane.checkForContentChange()  if activePane instanceof IDEEditorPane


  ###*
   * Open a series of file paths, in the format of klient's openFiles
   * event.
   *
   * @param {Object} eventData - An object formatted as a Klient event
   *  data.
   * @param {Array<string>} eventData.files - A list of file paths
  ###
  handleKlientOpenFiles: (eventData) ->

    @openFiles eventData.files
    return eventData


  isTabViewFocused: (tabView) ->

    return @activeTabView is tabView


  setActiveTabView: (tabView) ->

    activePane = tabView.getActivePane()

    for view in @ideViews
      for tab in view.holderView.tabs.subViews
        if tab is activePane?.tabHandle
        then activePane.tabHandle.setClass 'focus'
        else tab.unsetClass 'focus'

    return  if tabView is @activeTabView
    return  if tabView.isDestroyed

    @setActivePaneFocus off, yes
    @activeTabView = tabView
    @setActivePaneFocus on


  setActivePaneFocus: (state, force = no) ->

    return  unless pane = @getActivePaneView()
    return  if pane is @activePaneView and not force

    @turnOffTerminalSizeListener()

    @activePaneView = pane

    @listenForTerminalSizeChanges()

    kd.utils.defer -> pane.setFocus? state


  ###*
   * @param {Object} options
  ###
  splitTabView: (options) ->

    { type, ideViewOptions, dontSave, newIdeViewHash, silent } = options

    ideView        = @activeTabView.parent
    ideParent      = ideView.parent
    newIdeView     = new IDEView ideViewOptions

    newIdeView.setHash newIdeViewHash

    splitViewPanel = @activeTabView.parent.parent
    if splitViewPanel instanceof kd.SplitViewPanel
    then layout = splitViewPanel._layout
    else layout = @layout

    @setActivePaneFocus off, yes
    @activeTabView = null

    ideView.detach()

    splitView = new kd.SplitView
      type  : type
      views : [ null, newIdeView ]

    layout.split(type is 'vertical')
    splitView._layout = layout

    @registerIDEView newIdeView

    splitView.once 'viewAppended', =>
      splitView.panels.first.attach ideView
      splitView.panels[0] = ideView.parent
      splitView.options.views[0] = ideView

      splitView.panels.forEach (panel, i) =>
        leaf          = layout.leafs[i]
        panel._layout = leaf
        @layoutMap[leaf.data.offset] = panel

      @doResize()

    ideParent.addSubView splitView
    @setActiveTabView newIdeView.tabView

    splitView.on 'ResizeDidStop', kd.utils.throttle 500, @bound 'doResize'
    splitView.on 'ResizeDidStop', kd.utils.debounce 750, @bound 'saveLayoutSize'

    if not silent
      newIdeView.emit 'NewSplitViewCreated',
        ideView    : ideView
        newIdeView : newIdeView
        direction  : type

    @recalculateHandles()
    @writeSnapshot()  unless dontSave
    @resizeActiveTerminalPane()


  recalculateHandles: ->

    closeHandleMethod = if @ideViews.length > 1
    then 'showCloseHandle'
    else 'hideCloseHandle'

    @ideViews.forEach (view) ->
      view.holderView[closeHandleMethod]()
      view.ensureSplitHandlers()

  ###*
   * @param {boolean=} silent  Don't dispatch the `SplitViewWasMerged` event if it is `yes`
  ###
  mergeSplitView: (silent = no) ->

    tabView     = @activeTabView
    panel       = tabView.parent.parent
    splitView   = panel.parent
    ideViewHash = tabView.parent.hash
    { parent }  = splitView

    return  unless panel instanceof kd.SplitViewPanel

    # Remove merged `ideView` from `ideViews`
    index = @ideViews.indexOf tabView.parent
    @ideViews.splice index, 1

    # Detect the next `ideView`.
    index = if index < @ideViews.length - 1 then index++ else @ideViews.length - 1
    targetIdeView = @ideViews[index]

    return  unless targetIdeView

    for pane in tabView.panes.slice 0
      tabView.removePane pane, yes, (yes if tabView instanceof IDEApplicationTabView)
      targetIdeView.tabView.addPane pane

    @setActiveTabView targetIdeView.tabView

    panel.destroy() # Remove panel.

    # Remove destroyed panel from array.
    splitView.panels       = _.compact splitView.panels
    splitView.beingResized = yes  # Mark as resized because DOM was deleted.
    splitView.detach()  # Detach `splitView` from DOM.

    # Point shot.
    # `targetView` can be a `kd.SplitView` or an `IDEView`.
    targetView = splitView.panels.first.getSubViews().first
    targetView.unsetParent()  # Remove `parent` of `targetView`.

    parent.attach targetView  # Attach again.

    @updateLayoutMap_ splitView, targetView

    # I'm not sure about the usage of private method. I had to...
    # Is it the best way for view resizing?
    targetView._windowDidResize()

    if not silent
      targetIdeView.emit 'SplitViewMerged', { ideViewHash, targetIdeView }

    @doResize()
    @recalculateHandles()
    @resizeActiveTerminalPane()
    @writeSnapshot()


  ###*
   * Open new file with options
   *
   * @param {Object} options
   * @param {Function=} callback  is optional parameter
  ###
  openFile: (options, callback = kd.noop) ->

    { file, contents, emitChange, targetTabView, switchIfOpen, isActivePane } = options

    if switchIfOpen
      wasOpen = no

      @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
        if FSHelper.plainPath(editorPane.file.path) is file.path
          editorPane.emit 'ShowMeAsActive'
          callback editorPane
          wasOpen = yes

      return if wasOpen

    @setActiveTabView targetTabView  if targetTabView

    @activeTabView.emit 'FileNeedsToBeOpened', file, contents, callback, emitChange, isActivePane


  ###*
   * Open multiple file paths, loading the contents.
   *
   * @param {Array<string>} filePaths - A list of file paths.
  ###
  openFiles: (filePaths) ->

    unless filePaths
      return kd.error 'IDEAppController::openFiles: Called with empty files'

    filePaths.forEach (path) =>
      file = FSHelper.createFileInstance { path, machine: @mountedMachine }
      file.fetchContents yes, (err, contents) =>
        return kd.error err  if err
        @openFile { file, contents }


  ###*
   * Watch given file with options
   *
   * @param {Object} options
   * @param {Function=} callback  is optional parameter
  ###
  tailFile: (options, callback = kd.noop) ->

    { file, contents, targetTabView, description,
      emitChange, isActivePane, tailOffset } = options

    targetTabView = @ideViews.first.tabView  unless targetTabView

    @setActiveTabView targetTabView

    @activeTabView.emit 'FileNeedsToBeTailed', {
      file, contents, description, callback, emitChange,
      isActivePane, tailOffset
    }


  openMachineTerminal: (machineData) ->

    @activeTabView.emit 'MachineTerminalRequested', machineData


  openMachineWebPage: (machineData) ->

    @activeTabView.emit 'MachineWebPageRequested', machineData


  openReadme: (machine) ->

    machine or= @mountedMachine
    owner   = machine.getOwner()
    path    = "/home/#{owner}/README.md"
    file    = FSHelper.createFileInstance { path, machine }

    file.fetchContents (err, contents = '') =>
      # no need to do anything if there is an error.
      return kd.warn 'Failed to open README.md', err  if err

      @setActiveTabView @ideViews.first.tabView
      @openFile { file, contents, switchIfOpen: yes }


  updateMachineRoot: ->

    { finderController } = @finderPane

    @mountedMachine.fetchInfo (err, info) =>
      debug 'machine.fetchInfo res', { err, info }
      kd.warn '[IDE] Failed to fetch info', err  if err
      rootPath = info?.home or '/'
      debug 'updating machine root as', @mountedMachine.uid, rootPath
      finderController.updateMachineRoot @mountedMachine.uid, rootPath


  mountMachine: (machineData) ->

    # interrupt if workspace was changed
    # return  if machineData.uid isnt @workspaceData.machineUId

    panel     = @workspace.getView()
    filesPane = panel.getPaneByName 'filesPane'

    @workspace.ready =>
      filesPane.emit 'MachineMountRequested', machineData
      @updateMachineRoot()


  unmountMachine: (machineData) ->

    panel     = @workspace.getView()
    filesPane = panel.getPaneByName 'filesPane'

    filesPane.emit 'MachineUnmountRequested', machineData


  isMachineRunning: ->

    return @mountedMachine?.status.state is Running


  createInitialView: (withFakeViews) ->

    @getMountedMachine (err, machine) => @workspace.ready =>

      return  unless machine

      for ideView in @ideViews
        ideView.mountedMachine = @mountedMachine

      if not @isMachineRunning() or withFakeViews

        nickname     = machine.getOwner()
        machineLabel = machine.slug or machine.label
        splashes     = splashMarkups

        @fakeTabView      = @activeTabView
        fakeTerminalView  = new kd.CustomHTMLView { partial: splashes.getTerminal nickname }
        @fakeTerminalPane = @fakeTabView.parent.createPane_ fakeTerminalView, { name: 'Terminal' }
        @fakeFinderView   = new kd.CustomHTMLView { partial: splashes.getFileTree nickname, machineLabel }

        @finderPane.addSubView @fakeFinderView, '.nfinder .jtreeview-wrapper'

      else

        @fetchSnapshot (snapshot) =>

          # Just resurrect snapshot for host or without collaboration.
          # Because we need check the `@myWatchMap` and it is not possible here.
          if snapshot and (@amIHost or @mountedMachine.isPermanent())
            return @layoutManager.resurrectSnapshot snapshot

          # Be quiet. Don't write initial views's changes to snapshot.
          # After that, get participant's snapshot from collaboration data and build workspace.
          @silent = yes  if @isInSession and not @amIHost and not @mountedMachine.isPermanent()

          @addInitialViews()

          return


  setMountedMachine: (machine) ->

    @mountedMachine = machine
    @emit 'MachineDidMount', machine  if machine


  whenMachineReady: (callback) ->

    if @mountedMachine
    then callback @mountedMachine
    else @once 'MachineDidMount', callback


  getMountedMachine: (callback = noop) ->

    unless @mountedMachineUId
      return callback null, null

    if @mountedMachine
      return callback null, @mountedMachine

    cc = kd.singletons.computeController
    machine = cc.storage.machines.get 'uid', @mountedMachineUId
    @setMountedMachine machine
    callback null, machine


  showNoMachineState: ->

    return  if @noStackFoundView

    @getView().addSubView @noStackFoundView = new NoStackFoundView


  mountMachineByMachineUId: (machineUId, done = kd.noop) ->

    return  if @mountedMachine

    computeController = kd.getSingleton 'computeController'
    container         = @getView()
    withFakeViews     = no

    mount = (machineItem) =>

      unless machineItem
        return @showNoMachineState()

      @setMountedMachine machineItem
      @prepareIDE withFakeViews

      return no  if withFakeViews

      if machineItem
        { state } = machineItem.status
        machineId = machineItem._id

        if state is Running
          machineItem.getBaseKite()?.fetchTerminalSessions()
          @mountMachine machineItem
          @prepareCollaboration()
          @bindKlientEvents machineItem
          @runOnboarding()

        else
          unless @machineStateModal

            @createMachineStateModal {
              state, container, machineItem, initial: yes
            }

          @once 'IDEReady', =>
            @prepareCollaboration()
            @runOnboarding()

        @bindMachineEvents machineItem

        adminMessage = new StackAdminMessageController {
          container
          machine : machineItem
        }
        adminMessage.showIfNeeded()

      else
        return @showNoMachineState()

    cc = kd.singletons.computeController
    machine = cc.storage.machines.get 'uid', machineUId
    mount machine
    done()


  bindMachineEvents: (machineItem) ->

    actionRequiredStates = [Stopping, Stopped, Terminating, Terminated]

    kd.getSingleton 'computeController'

      .on "public-#{machineItem._id}", (event) =>

        if event.status in actionRequiredStates
          @showStateMachineModal machineItem, event

        switch event.status
          when Terminated, Terminating then @handleMachineTerminated()


  handleMachineTerminated: ->

    { appManager, router } = kd.singletons
    if appManager.frontApp is this
      kd.utils.defer -> router.handleRoute '/IDE'

    @quit reload = no


  showStateMachineModal: (machineItem, event) ->

    machineItem.getBaseKite( no ).disconnect()

    if @machineStateModal

      if event.status is Stopping
        event.percentage = 100 - event.percentage
        @machineStateModal.unsetClass 'full'

      @machineStateModal.updateStatus event
    else
      { state }   = machineItem.status
      container = @getView()
      @createMachineStateModal { state, container, machineItem }


  createMachineStateModal: (options = {}) ->

    { state, container, machineItem, initial } = options

    container   ?= @getView()
    modalOptions = { state, container, initial }

    @machineStateModal = new ResourceStateModal modalOptions, machineItem
    @machineStateModal.once 'KDObjectWillBeDestroyed', => @machineStateModal = null
    @machineStateModal.once 'OperationCompleted', @bound 'handleIDEBecameReady'

    @emit 'MachineStateModalReady', @machineStateModal

    # stop IDE onboarding if it's running
    # since machine state is changed and state modal appears,
    # onboarding throbbers will be unavailable and should be hidden
    @stopOnboarding()


  showMachineStateModal: ->

    return @machineStateModal.show()  if @machineStateModal
    @once 'MachineStateModalReady', => @machineStateModal.show()


  hideMachineStateModal: (skipOverlay) ->

    return @machineStateModal.hide skipOverlay  if @machineStateModal
    @once 'MachineStateModalReady', => @machineStateModal.hide skipOverlay


  collapseSidebar: ->

    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first
    filesPane    = panel.getPaneByName 'filesPane'
    { tabView }  = filesPane
    desiredSize  = 250

    splitView.resizePanel 39, 0
    @getView().setClass 'sidebar-collapsed'
    floatedPanel.setClass 'floating'
    @activeFilesPaneName = tabView.activePane.name
    tabView.showPaneByName 'Dummy'

    @isSidebarCollapsed = yes

    splitView.emit 'ResizeFirstSplitView' # It references to main wrapper split view.
    @resizeAllSplitViews() # Also resize all split views.

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

    splitView.emit 'ResizeFirstSplitView'
    @resizeAllSplitViews()


  resizeAllSplitViews: ->

    parents = []
    @ideViews.forEach (view) ->
      parent = view.parent?.parent
      if parent and parent instanceof kd.SplitView
        parents.push parent

    _.uniq(parents, 'id').forEach (p) -> p._windowDidResize()
    @doResize()


  toggleSidebar: ->

    if @isSidebarCollapsed then @expandSidebar() else @collapseSidebar()


  splitVertically: ->

    @splitTabView { type: 'vertical' }


  splitHorizontally: ->

    @splitTabView { type: 'horizontal' }

  createNewFile: do ->
    newFileSeed = 1

    return ->
      path     = "localfile:/Untitled-#{newFileSeed++}.txt@#{Date.now()}"
      file     = FSHelper.createFileInstance { path, machine: @mountedMachine }
      contents = ''

      @openFile { file, contents }


  createNewTerminal: (options = {}) ->

    @activeTabView.emit 'TerminalPaneRequested', options


  createNewBrowser: (url) ->

    url = ''  unless typeof url is 'string'

    @activeTabView.emit 'PreviewPaneRequested', url


  createNewDrawing: (paneHash) ->

    paneHash = null unless typeof paneHash is 'string'

    @activeTabView.emit 'DrawingPaneRequested', paneHash


  moveTab: (direction) ->

    tabView = @activeTabView
    return unless tabView?.parent

    panel = tabView.parent.parent
    return  unless panel instanceof kd.SplitViewPanel

    targetOffset = @layout[direction](panel._layout.data.offset)
    return  unless targetOffset?

    targetPanel = @layoutMap[targetOffset]

    return  unless targetPanel?.subViews.first.tabView   # Defensive check.

    { pane }      = tabView.removePane tabView.getActivePane(), yes
    { view }      = pane
    targetTabView = targetPanel.subViews.first.tabView

    targetTabView.addPane pane
    @setActiveTabView targetPanel.subViews.first.tabView
    @doResize()

    targetTabView.parent.emit 'IDETabMoved', { view, tabView, targetTabView }


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

    @activeTabView?.showPaneByIndex index


  goToLine: ->

    @activeTabView.emit 'GoToLineRequested'
    @contentSearch.destroy()  if @contentSearch
    @findAndReplaceView.hide()  if @findAndReplaceView


  closeTab: ->

    @activeTabView.removePane @activeTabView.getActivePane()


  registerIDEView: (ideView) ->

    @ideViews.push ideView
    ideView.mountedMachine = @mountedMachine

    ideView.on 'PaneRemoved', (pane) =>
      ideViewLength  = 0
      ideViewLength += ideView.tabView.panes.length  for ideView in @ideViews

      return unless pane.view?.hash

      delete @generatedPanes[pane.view.hash]

      if not @isDisabled() and session = pane.view.remote?.session
        # we need to check against kite existence because while a machine
        # is getting destroyed/stopped/reinitialized we are invalidating it's
        # kite instance to make sure every call is stopped. ~ GG
        @mountedMachine.getBaseKite()?.removeFromActiveSessions? session

      @statusBar.showInformation()  if ideViewLength is 0
      @writeSnapshot()

    ideView.tabView.on 'PaneAdded', (pane) =>
      @registerPane pane
      @writeSnapshot()

    ideView.on 'ChangeHappened', (change) => @syncChange change
    ideView.on 'UpdateWorkspaceSnapshot', => @writeSnapshot()

    ideView.on 'NewEditorPaneCreated', (pane) =>
      @emit 'EditorPaneDidOpen', pane

  isDisabled: ->
    @isDestroyed or not @mountedMachine or not @isMachineRunning()

  writeSnapshot: ->

    return  if @isDisabled() or @silent

    key   = @getWorkspaceStorageKey nick()
    value = @getWorkspaceSnapshot()

    @writeToKiteStorage key, value
    @emit 'SnapshotUpdated'


  writeToKiteStorage: (key, value) ->

    machine = @mountedMachine
    return  unless machine.isRunning()

    kite = machine.getBaseKite()
    kite.init().then ->
      kite.storageSetQueued key, value
      return kite
    .catch kd.noop


  saveLayoutSize: ->

    return  if @isDisabled()

    username  = nick()
    key       = @getWorkspaceStorageKey "#{username}-LayoutSize"
    value     = @getLayoutSizeData()

    @writeToKiteStorage key, value
    @emit 'LayoutSizesSaved'


  fetchLayoutSize: (callback, username = nick()) ->

    key = "#{username}-LayoutSize"
    @fetchFromKiteStorage callback, key


  removeWorkspaceSnapshot: (username = nick()) ->

    return  if @isDisabled()

    key = @getWorkspaceStorageKey username
    @mountedMachine.getBaseKite().storageDelete key


  getWorkspaceStorageKey: (prefix) ->

    if prefix
      return "#{prefix}.wss.#{@mountedMachine.uid}"
    else
      return "wss.#{@mountedMachine.uid}"


  registerPane: (pane) ->

    { view } = pane
    return  unless view?.hash?

    @generatedPanes or= {}
    @generatedPanes[view.hash] = yes

    view.on 'ChangeHappened', (change) => @syncChange change


  forEachSubViewInIDEViews_: (callback = noop, paneType) ->

    if typeof callback is 'string'
      [paneType, callback] = [callback, paneType]

    for ideView in @ideViews
      for pane in ideView.tabView.panes when pane
        return  unless view = pane.getSubViews().first
        if paneType
        then callback view  if view.getOptions().paneType is paneType
        else callback view


  updateSettings: (component, key, value, silent) ->

    # TODO: Refactor this method by passing component type to helper method.
    Class  = if component is 'editor' then IDEEditorPane else IDETerminalPane
    method = "set#{key.capitalize()}"

    if key is 'useAutosave' # autosave is special case, handled by app manager.
      return if value then @enableAutoSave() else @disableAutoSave()

    @forEachSubViewInIDEViews_ (view) ->
      if view instanceof Class
        if component is 'editor'
          view.getAce()[method]? value, silent
        else
          view.webtermView.updateSettings()


  initiateAutoSave: ->

    { editorSettingsView } = @settingsPane

    editorSettingsView.on 'SettingsFetched', =>
      @enableAutoSave()  if editorSettingsView.settings.useAutosave


  enableAutoSave: ->

    return  if @autoSaveInterval
    @autoSaveInterval = kd.utils.repeat 1000, =>
      @forEachSubViewInIDEViews_ 'editor', (ep) -> ep.handleAutoSave()


  disableAutoSave: ->

    kd.utils.killRepeat @autoSaveInterval
    @autoSaveInterval = null


  getActivePaneView: ->

    return @activeTabView?.getActivePane()?.getSubViews().first


  saveFile: ->

    @getActivePaneView().emit 'SaveRequested'


  saveAs: ->

    @getActivePaneView().aceView.ace.requestSaveAs()


  saveAllFiles: ->

    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      editorPane.emit 'SaveRequested'


  previewFile: ->

    view     = @getActivePaneView()
    { file } = view.getOptions()
    return unless file

    if FSHelper.isPublicPath file.path
      nickname    = @collaborationHost or nick()
      [temp, src] = FSHelper.plainPath(file.path).split '/Web'
      @createNewBrowser "#{@mountedMachine.domain}/#{src}"
    else
      @notify 'File needs to be under ~/Web folder to preview.', 'error'


  updateStatusBar: (component, data) ->

    { status } = @statusBar

    text = if component is 'editor'
      { cursor, file } = data
      filePath = if file.isDummyFile() then file.name else file.path

      """
        <p class="line">#{++cursor.row}:#{++cursor.column}</p>
        <p>#{Encoder.XSSEncode FSHelper.minimizePath filePath}</p>
      """

    else if component is 'terminal' then "Terminal on #{data.machineName}"

    else if component is 'searchResult'
    then """Search results for #{data.searchText}"""

    else if typeof data is 'string' then data

    else ''

    status.updatePartial text


  showStatusBarMenu: (tabHandle, button) ->

    @setActiveTabView tabHandle.getDelegate()

    paneView = @getActivePaneView()
    paneType = paneView?.getOptions().paneType or null

    delegate = button
    menu     = new IDEStatusBarMenu { paneType, paneView, delegate }

    tabHandle.menu = menu

    menu.on 'viewAppended', ->
      if paneType is 'editor' and paneView
        { syntaxSelector } = menu
        { ace }            = paneView.aceView

        syntaxSelector.select.setValue ace.getSyntax() or 'text'
        syntaxSelector.on 'SelectionMade', (value) ->
          ace.setSyntax value


  showRenameTerminalView: ->

    paneView = @getActivePaneView()
    paneType = paneView?.getOptions().paneType
    tabView  = paneView?.parent

    return  unless paneType in ['terminal', 'editor']

    tabView.tabHandle.setTitleEditMode yes


  suspendTerminal: ->

    paneView = @getActivePaneView()

    return  unless paneView

    { parent } = paneView

    paneView.webtermView.suspend = yes # Mark it as suspended mode is active
    parent.getDelegate().handleCloseAction parent, no # Trigger close action.


  showFileFinder: ->

    return @fileFinder.input.setFocus()  if @fileFinder

    @fileFinder = new IDEFileFinder
    @findAndReplaceView.hide()  if @findAndReplaceView
    @contentSearch.destroy()  if @contentSearch
    @activeTabView.emit 'GotoLineNeedsToBeClosed'
    @splitViewPanel.addSubView @fileFinderOverlay = new KDOverlayView
      cssClass : 'file-finder-overlay'
    @fileFinder.once 'KDObjectWillBeDestroyed', =>
      @fileFinder = null
      @fileFinderOverlay.remove()


  showContentSearch: ->

    return @contentSearch.findInput.setFocus()  if @contentSearch

    data = { machine: @mountedMachine }
    rootPath = '/' # FIXME ~ GG
    @splitViewPanel.addSubView @contentSearch = new IDEContentSearchView  { rootPath }, data
    @findAndReplaceView.hide()  if @findAndReplaceView
    @activeTabView.emit 'GotoLineNeedsToBeClosed'
    @contentSearch.once 'KDObjectWillBeDestroyed', =>
      @contentSearch = null
    @contentSearch.once 'ViewNeedsToBeShown', (view) =>
      @activeTabView.emit 'ViewNeedsToBeShown', view


  createStatusBar: (splitViewPanel) ->

    splitViewPanel.addSubView @statusBar = new IDEStatusBar


  createFindAndReplaceView: (splitViewPanel) ->

    { windowController } = kd.singletons
    cssName = 'in-find-mode'

    splitViewPanel.addSubView @findAndReplaceView = new AceFindAndReplaceView
    @findAndReplaceView.hide()

    @findAndReplaceView.on 'FindAndReplaceViewClosed', =>
      @getView().unsetClass cssName
      @getActivePaneView().aceView?.ace.focus()
      @isFindAndReplaceViewVisible = no

      windowController.notifyWindowResizeListeners()
    @findAndReplaceView.on 'FindAndReplaceViewShown', (withReplace) =>
      @contentSearch.destroy()  if @contentSearch
      @activeTabView.emit 'GotoLineNeedsToBeClosed'
      view = @getView()
      if withReplace then view.setClass cssName else view.unsetClass cssName

      windowController.notifyWindowResizeListeners()


  showFindReplaceView: (withReplaceMode) ->
    view = @findAndReplaceView
    @setFindAndReplaceViewDelegate()
    @isFindAndReplaceViewVisible = yes
    view.show withReplaceMode
    view.setTextIntoFindInput '' # FIXME: Set selected text if exists


  showFindView: -> @showFindReplaceView no

  showFindAndReplaceView: -> @showFindReplaceView yes

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


  handleIDEBecameReady: (machine, initial = no) ->

    { computeController } = kd.singletons

    debug 'handleIDEBecameReady', { machine, initial }

    # when MachineStateModal calls this func, we need to rebind Klient.
    @bindKlientEvents machine
    @updateMachineRoot()

    machine.getBaseKite()?.fetchTerminalSessions?()

    @fetchSnapshot (snapshot) =>

      debug 'snapshot fetched', snapshot

      unless @fakeViewsDestroyed
        @removeFakeViews()
        @fakeViewsDestroyed = yes

      unless @layoutManager.isSnapshotRestored()

        # Just resurrect snapshot for the host with/without a session.
        if snapshot and @amIHost
          if @getActiveInstance().isActive
          then @layoutManager.resurrectSnapshot snapshot
          else @layoutManager.setSnapshot snapshot
        else
          @addInitialViews()  unless @initialViewsReady

      if initial
        computeController.showBuildLogs machine, INITIAL_BUILD_LOGS_TAIL_OFFSET

      debug 'firing ready event IDEReady'
      @emit 'IDEReady'

    return null


  removeFakeViews: ->

    @fakeTerminalPane?.parent?.removePane @fakeTerminalPane
    @fakeFinderView?.destroy()


  addInitialViews: ->

    @ideViews.first.createTerminal { machine: @mountedMachine }
    @setActiveTabView @ideViews.first.tabView
    @initialViewsReady = yes

    @forEachSubViewInIDEViews_ (pane) ->
      pane.isInitial = yes

    return


  toggleFullscreenIDEView: ->

    @activeTabView.parent.toggleFullscreen()


  doResize: kd.utils.debounce 100, ->

    @forEachSubViewInIDEViews_ (pane) =>
      { paneType } = pane.options
      switch paneType
        when 'terminal'
          { webtermView } = pane
          { terminal }    = webtermView

          pane.ready =>

            terminal.updateSize yes  if terminal

            if not @isInSession and @getActiveInstance().isActive
              kd.utils.wait 400, -> # defer was not enough.
                webtermView.triggerFitToWindow()

        when 'editor', 'tailer'
          height   = pane.getHeight()
          { ace }  = pane.aceView

          pane.ready ->
            ace.setHeight height
            ace.editor.resize()

      tabPaneView = pane.parent
      tabView     = tabPaneView.getDelegate()
      tabView.resizeTabHandles()


  notify: (title, cssClass = 'success', type = 'mini', duration = 4000) ->

    return unless title
    new kd.NotificationView { title, cssClass, type, duration }


  resizeActiveTerminalPane: ->

    @forEachSubViewInIDEViews_ 'terminal', (tl) ->
      tl.webtermView.terminal?.updateSize yes


  removePaneFromTabView: (pane, shouldDetach = no) ->

    paneView = pane.parent
    tabView  = paneView.parent
    tabView.removePane paneView


  getWorkspaceSnapshot: -> @layoutManager.createLayoutData()


  getLayoutSizeData: -> @layoutManager.createLayoutSizeData()


  changeActiveTabView: (paneType) ->

    if paneType is 'terminal'
      @setActiveTabView @ideViews.last.tabView
    else
      @setActiveTabView @ideViews.first.tabView


  syncChange: (change) ->

    { context } = change

    return  if not @rtm or not @rtm.isReady or not context

    change.rtmHash              = @rtm.hash
    { paneHash, ideViewHash }   = context
    nickname                    = nick()

    if change.origin is nickname

      if context.paneType is 'editor'

        if change.type is 'NewPaneCreated'

          { content, path } = context.file
          string = @rtm.getFromModel path

          unless string
            @rtm.create 'string', path, content

        else if change.type is 'ContentChange'

          { content, path } = context.file

          return  unless content?

          string = @rtm.getFromModel path
          string.setText content  if string

        if context.file?.content
          delete context.file.content

      if @amIHost and change.type is 'FileTreeInteraction'
        @saveOpenFoldersToDrive()

      @changes.push change


  ###*
   * @param {string} origin  Nickname of the change's owner
   * @return {boolean}
  ###
  amIWatchingChangeOwner: (origin) ->

    return  if not @myWatchMap or not @myWatchMap.keys()

    return @myWatchMap.keys().indexOf(origin) > -1


  handleChange: (change) ->

    { context, origin, type, rtmHash } = change

    return if not context or not origin or (origin is nick() and rtmHash is @rtm.hash)

    mustSyncChanges = [ 'FileSaved' ]

    if @permissions.get(origin) is 'edit'
      mustSyncChanges.push 'CursorActivity'

    if @amIWatchingChangeOwner(origin) or (type in mustSyncChanges) or (origin is nick())
      targetPane = @getPaneByChange change

      if type is 'NewPaneCreated'
        @createPaneFromChange change

      else if type is 'NewSplitViewCreated'
        @handleSplitViewChanges change, =>
          @splitTabView
            type            : context.direction
            newIdeViewHash  : context.newIdeViewHash
            silent          : yes

      else if type is 'SplitViewMerged'
        @handleSplitViewChanges change, =>
          @mergeSplitView yes

      else if type is 'IDETabMoved'
        @handleMoveTabChanges context

      else if type is 'FileSaved'
        targetPane?.file.emit 'FileContentsNeedsToBeRefreshed'

      else if type is 'TerminalScreenSizeChanged'
        @handleTerminalScreenSizeChanged change

      else if type in ['TabChanged', 'PaneRemoved', 'TerminalRenamed']
        paneView = targetPane?.parent
        tabView  = paneView?.parent
        ideView  = tabView?.parent

        return unless ideView

        ideView.suppressChangeHandlers = yes

        switch type
          when 'TabChanged'  then tabView.showPane paneView
          when 'PaneRemoved' then tabView.removePane paneView, no, yes
          when 'TerminalRenamed'
            ideView.renameTerminal paneView, @mountedMachine, context.session

        ideView.suppressChangeHandlers = no

      targetPane?.handleChange? change, @rtm


  handleTerminalScreenSizeChanged: (change) ->

    targetPane = @getPaneByChange change

    return  unless targetPane

    { size } = change.context

    { terminal } = targetPane.webtermView

    swidth = terminal.parent.getWidth()
    { width: charWidth } = terminal.getCharSizes()
    newCols = Math.max 1, Math.floor swidth / charWidth

    if size.w > newCols
      terminal.updateSize yes
      kd.utils.wait 400, ->
        targetPane.webtermView.triggerFitToWindow()
    else
      terminal.setSize size.w, size.h, no


  ###*
   * @param {Object} context
  ###
  handleMoveTabChanges: (context) ->

    originTabView = @getTabViewByIDEViewHash context.originIDEViewHash
    targetTabView = @getTabViewByIDEViewHash context.targetIDEViewHash

    return  if not originTabView or not targetTabView

    @forEachSubViewInIDEViews_ context.paneType, (p) =>

      if p.hash is context.paneHash

        check = originTabView.panes.filter (p) -> p.hash is context.paneHash
        if not originTabView.panes.length or not check.length
          originTabView = p.parent.parent # Reach the `IDEApplicationTabView`

        originTabView.activePane = null
        { pane } = originTabView.removePane p.parent, yes, yes

        originTabView.showPaneByIndex 0  if originTabView.panes.length

        kd.utils.defer =>
          targetTabView.addPane pane

          # Update `AceView`s delegate
          if pane.view instanceof IDEEditorPane
            pane.view.updateAceViewDelegate targetTabView.parent

          @setActiveTabView targetTabView
          @doResize()


  ###*
   * @param {Object} change
   * @param {Function=} callback
  ###
  handleSplitViewChanges: (change, callback = kd.noop) ->

    tabView = @getTabViewByIDEViewHash change.context.ideViewHash
    return  unless tabView

    @setActiveTabView tabView
    callback()


  getPaneByChange: (change) ->

    return unless change.context

    return @finderPane  if change.type is 'FileTreeInteraction'

    targetPane    = null
    { context }   = change
    { paneType }  = context
    paneHash      = context.paneHash or context.hash

    @forEachSubViewInIDEViews_ paneType, (pane) ->

      if paneType in [ 'editor', 'tailer' ]
        isSameFilePath  = pane.getFile()?.path is context.file?.path
        isSamePaneType  = pane.options.paneType is paneType
        isInSameIdeView = pane.ideViewHash is context.ideViewHash

        if isSameFilePath and isSamePaneType and isInSameIdeView
          targetPane = pane
      else
        targetPane = pane  if pane.hash is paneHash

    return targetPane


  createPaneFromChange: (change = {}, isFromLocalStorage) ->

    return  if not @rtm and not isFromLocalStorage

    { context, origin } = change
    return  unless context

    paneHash = context.paneHash or context.hash

    { paneType, ideViewHash } = context

    return  if not paneType or not paneHash

    # if the pane is already opened on IDE, don't re-open it. Show it.
    if pane = @getPaneByChange change
      paneView = pane.parent
      tabView  = paneView.parent
      return tabView.showPane paneView


    if ideViewHash and @amIWatchingChangeOwner(origin) or origin is nick()
      targetTabView = @getTabViewByIDEViewHash ideViewHash
      @setActiveTabView targetTabView  if targetTabView

    switch paneType
      when 'terminal' then @createTerminalPaneFromChange change, paneHash
      when 'editor'   then @createEditorPaneFromChange change, paneHash
      when 'drawing'  then @createDrawingPaneFromChange change, paneHash
      when 'tailer'   then @createEditorPaneFromChange change, paneHash, yes


  createTerminalPaneFromChange: (change, hash) ->

    { context } = change

    @createNewTerminal
      machine       : @mountedMachine
      session       : context.session
      hash          : hash
      joinUser      : @collaborationHost or nick()
      fitToWindow   : not @isInSession
      isActivePane  : context.isActivePane


  createEditorPaneFromChange: (change, hash, inTailMode) ->

    { context, targetTabView }        = change
    { file, paneType, isActivePane }  = context

    { path }       = file
    options        = { path, machine : @mountedMachine }
    file           = FSHelper.createFileInstance options
    file.paneHash  = hash
    method         = if inTailMode then 'tailFile' else 'openFile'

    if @rtm?.realtimeDoc
      contents = @rtm.getFromModel(path)?.getText() or ''
      @[method] { file, contents, emitChange: no, targetTabView, isActivePane }

    else if file.isDummyFile()
      @[method] { file, contents: context.file.content, emitChange: no }

    else
      file.fetchContents (err, contents = '') =>
        return showError err  if err
        @[method] { file, contents, emitChange: no, targetTabView, isActivePane }


  createDrawingPaneFromChange: (change, hash) ->

    @createNewDrawing hash


  showModal: (modalOptions = {}, callback = noop) ->
    return  if @modal

    modalOptions.cssClass = 'content-modal'
    modalOptions.overlay  ?= yes
    modalOptions.blocking ?= no
    modalOptions.buttons or=
      No         :
        title    : 'Cancel'
        cssClass : 'solid cancel medium'
        callback : => @modal.destroy()
      Yes        :
        title    : 'Yes'
        cssClass : 'solid medium'
        loader   : yes
        callback : callback

    ModalClass = if modalOptions.blocking then kd.BlockingModalView else kd.ModalView
    @modal = new ContentModal modalOptions
    @modal.once 'KDObjectWillBeDestroyed', =>
      delete @modal


  quit: (reload = yes, stopCollaborationSession = yes) ->

    return  if @getView().isDestroyed

    @emit 'IDEWillQuit'
    @mountedMachine?.getBaseKite(createIfNotExists = no).disconnect()
    @stopCollaborationSession()  if stopCollaborationSession

    if reload

      kd.singletons.appManager.quit this, =>
        route = if @mountedMachine then "/IDE/#{@mountedMachine.slug}" else '/IDE'
        kd.singletons.router.handleRoute route

    else

      @cleanupCollaboration()
      @setMountedMachine null
      kd.singletons.router.handleRoute '/IDE'

    @once 'KDObjectWillBeDestroyed', @lazyBound 'emit', 'IDEDidQuit'



  beforeQuit: -> @quit reload = no


  removeParticipantCursorWidget: (targetUser) ->

    @forEachSubViewInIDEViews_ 'editor', (editorPane) ->
      editorPane.removeParticipantCursorWidget targetUser


  makeReadOnly: ->

    appView = @getView()

    ideView.isReadOnly = yes  for ideView in @ideViews
    @forEachSubViewInIDEViews_ (pane) -> pane.makeReadOnly()
    @finderPane.makeReadOnly()

    appView.setClass 'read-only'
    appView.on 'click', @bound 'readOnlyNotifierCallback_'  if @rtm.isReady


  readOnlyNotifierCallback_: -> @showRequestPermissionView()


  makeEditable: ->

    appView = @getView()

    ideView.isReadOnly = no  for ideView in @ideViews
    @forEachSubViewInIDEViews_ (pane) -> pane.makeEditable()
    @finderPane.makeEditable()

    appView.unsetClass 'read-only'
    appView.off 'click', @bound 'readOnlyNotifierCallback_'
    @requestEditPermissionView?.destroy()


  getActiveInstance: ->

    { appControllers } = kd.singletons.appManager
    instance = appControllers.IDE.instances[appControllers.IDE.lastActiveIndex]

    return { instance, isActive: instance is this }


  handleShortcut: (e) ->

    return  if not @layoutManager.isRestored and not @initialViewsReady
    return  unless @mountedMachine?.isRunning()
    return  if @getMyPermission() is 'read' and not @mountedMachine.isMine()

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

    return  unless @mountedMachine

    options        =
      title        : 'Machine access revoked'
      content      : '<p>Your access to this machine has been removed by its owner.</p>'
      blocking     : yes
      buttons      :
        quit       :
          style    : 'GenericButton'
          title    : 'OK'
          callback : =>

            { reactor } = kd.singletons
            reactor.dispatch actionTypes.INVITATION_REJECTED, @mountedMachine.getId()

            @modal.destroy()
            @quit()

    @showModal options


  fetchSnapshot: (callback, username = nick()) ->

    @fetchFromKiteStorage callback, username

    return


  fetchFromKiteStorage: (callback, prefix) ->

    if @isDisabled()
      return callback null

    handleError = (err) ->

      console.warn 'Failed to fetch data:', err
      callback null

      return err

    fetch = (prefix) =>

      key = @getWorkspaceStorageKey prefix
      @mountedMachine.getBaseKite().storageGet key

    fetch prefix

      .then (data) =>

        if data
          callback data
          return data

        # Backward compatibility plug
        unless @mountedMachine.isMine()
          callback null
          return null

        fetch()
          .then callback
          .catch handleError

        return data

      .catch handleError


  switchToPane: (options = {}) ->

    { context } = options

    return  unless context

    { hash } = context

    @forEachSubViewInIDEViews_ (view) ->

      return  unless view.hash is hash

      tabPane = view.parent
      tabView = tabPane.parent

      tabView.showPane tabPane


  removeInitialViews: ->

    @forEachSubViewInIDEViews_ (pane) =>
      @removePaneFromTabView pane  if pane.isInitial

    @mergeSplitView yes


  setTargetTabView: (tabView) ->

    @targetTabView = tabView


  handleTabDropped: (event, splitView, index) ->

    @moveTabToPanel @targetTabView, splitView, index  if @targetTabView

    @emit 'IDETabDropped'

    @removeAllSplitRegions()
    @targetTabView = null  # Reset


  handleTabDropToRegion: (direction, ideView) ->

    @removeAllSplitRegions()

    if direction is 'right' or direction is 'left'
      type = 'vertical'
    else
      type = 'horizontal'

    @setActiveTabView ideView.tabView
    @splitTabView { type }

    if direction is 'top' or direction is 'left'
      target = ideView.parent
    else
      target = @activeTabView.parent.parent

    @handleTabDropped null, target, null


  removeAllSplitRegions: ->

    for item in @ideViews
      item.emit 'RemoveSplitRegions' # Remove all "splitregions" div elements.


  moveTabToPanel: (tabView, targetPanel, index) ->

    return unless tabView.parent?

    { pane }      = tabView.removePane tabView.getActivePane(), yes, yes
    targetTabView = targetPanel.subViews.first.tabView

    if index?

      targetTabView.once 'PaneAdded', (paneInstance) ->

        { tabHandle } = paneInstance

        tabHandle.getDomElement().insertBefore @handles[index].domElement

        @handles.splice index, 0, tabHandle
        @panes.splice   index, 0, paneInstance


    targetTabView.addPane pane

    @setActiveTabView targetTabView
    @doResize()

    { view } = pane

    targetTabView.parent.emit 'IDETabMoved', { view, tabView, targetTabView }


  runOnboarding: ->

    { onboarding, appManager } = kd.singletons
    onboarding.run 'IDELoaded'  if appManager.frontApp is this


  stopOnboarding: ->

    { onboarding, appManager } = kd.singletons
    onboarding.stop 'IDELoaded'  if appManager.frontApp is this


  ###*
   * Update `@layoutMap` for move tab with keyboard shortcuts.
   *
   * @param {kd.SplitView|IDEView} parent
  ###
  updateLayoutMap_: (splitView, targetView) ->

    return  if targetView instanceof kd.SplitViewPanel

    @mergeLayoutMap_ splitView

    if targetView instanceof IDEView
      @mergeLayoutMap_ targetView.parent
    else
      targetView.panels.forEach (panel) =>
        @mergeLayoutMap_ panel


  ###*
   *
   * @param {kd.SplitViewPanel} view
  ###
  mergeLayoutMap_: (view) ->

    return  unless view instanceof kd.SplitViewPanel

    view._layout.leafs?.forEach (leaf) =>
      @layoutMap[leaf.data.offset] = null

    view._layout.merge()

    @layoutMap[view._layout.data.offset] = view


  ###*
   * Get/find an `ideView` by `hash`
   *
   * @param {string} hash
   * @return {IDEApplicationTabView}
  ###
  getTabViewByIDEViewHash: (hash) ->

    [ target ] = @ideViews.filter (ideView) -> ideView.hash is hash

    return target?.tabView


  resetDragState: ->

    @targetTabView = null
    @removeAllSplitRegions()


  turnOffTerminalSizeListener: ->

    @activePaneView?.webtermView?.off 'ScreenSizeChanged'


  listenForTerminalSizeChanges: ->

    @activePaneView?.webtermView?.on 'ScreenSizeChanged', (size) =>
      @updateStatusBar null, "Screen size changed to (#{size.w}, #{size.h})"
