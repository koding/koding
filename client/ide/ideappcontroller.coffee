ndpane = require 'ndpane'

RealTimeManager = require './realtimemanager'
splashMarkups   = require './splashMarkups'

AppControllerOptions = require './appcontrolleroptions'
IDEFilesTabView      = require './views/tabview/idefilestabview'
IDEView              = require './views/tabview/ideview'
Workspace            = require './workspace/workspace'
EditorPane           = require './workspace/panes/editorpane'
TerminalPane         = require './workspace/panes/terminalpane'
ShortcutsView        = require './views/shortcutsview/shortcutsview'
StatusBarMenu        = require './views/statusbar/statusbarmenu'
FileFinder           = require './views/filefinder/filefinder'
ContentSearch        = require './views/contentsearch/contentsearch'
StatusBar            = require './views/statusbar/statusbar'
ChatView             = require './views/chat/chatview'


class IDEAppController extends AppController

  {
    Stopped, Running, NotInitialized, Terminated, Unknown, Pending,
    Starting, Building, Stopping, Rebooting, Terminating, Updating
  } = Machine.State


  KD.registerAppClass this, new AppControllerOptions

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

    appView   = @getView()
    workspace = @workspace = new Workspace { layoutOptions }
    @ideViews = []

    # todo:
    # - following two should be abstracted out into a separate api
    @layout = ndpane(16)
    @layoutMap = new Array(16*16)

    {windowController} = KD.singletons
    windowController.addFocusListener @bound 'setActivePaneFocus'

    workspace.once 'ready', =>
      panel = workspace.getView()
      appView.addSubView panel

      panel.once 'viewAppended', =>
        ideView = panel.getPaneByName 'editorPane'
        @setActiveTabView ideView.tabView
        @registerIDEView  ideView

        splitViewPanel = ideView.parent.parent
        @createStatusBar splitViewPanel
        @createFindAndReplaceView splitViewPanel

        appView.emit 'KeyViewIsSet'

        @createInitialView()
        @bindCollapseEvents()

        {@finderPane, @settingsPane} = @workspace.panel.getPaneByName 'filesPane'

        @bindRouteHandler()
        @initiateAutoSave()

    KD.singletons.appManager.on 'AppIsBeingShown', (app) =>

      return  unless app instanceof IDEAppController

      @setActivePaneFocus on

      # Temporary fix for IDE is not shown after
      # opening pages which uses old SplitView.
      # TODO: This needs to be fixed. ~Umut
      KD.singletons.windowController.notifyWindowResizeListeners()

      @resizeActiveTerminalPane()


  bindRouteHandler: ->

    {router, mainView} = KD.singletons

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
      KD.utils.stopDOMEvent event  if event?
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

    KD.utils.defer -> pane.setFocus? state


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

    splitView.on 'ResizeDidStop', KD.utils.throttle 500, @bound 'doResize'


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
        {pane} = tabView.removePane p, yes, (yes if tabView instanceof AceApplicationTabView)
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

    @activeTabView.emit 'FileNeedsToBeOpened', file, contents, callback, emitChange


  openMachineTerminal: (machineData) ->

    @activeTabView.emit 'MachineTerminalRequested', machineData


  openMachineWebPage: (machineData) ->

    @activeTabView.emit 'MachineWebPageRequested', machineData


  mountMachine: (machineData) ->

    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'

    if machineData.isMine()
      rootPath   = @workspaceData?.rootPath or null
    else if owner = machineData.getOwner()
      rootPath   = "/home/#{owner}"
    else
      rootPath   = '/'

    filesPane.emit 'MachineMountRequested', machineData, rootPath


  unmountMachine: (machineData) ->

    panel     = @workspace.getView()
    filesPane = panel.getPaneByName 'filesPane'

    filesPane.emit 'MachineUnmountRequested', machineData


  createInitialView: ->

    KD.utils.defer =>
      @splitTabView 'horizontal', createNewEditor: no
      @getMountedMachine (err, machine) =>
        return unless machine
        {state} = machine.status

        if state in [ 'Stopped', 'NotInitialized', 'Terminated', 'Starting', 'Building' ]
          nickname     = KD.nick()
          machineLabel = machine.slug or machine.label
          splashs      = splashMarkups

          @fakeTabView      = @activeTabView
          @fakeTerminalView = new KDCustomHTMLView partial: splashs.getTerminal nickname
          @fakeTerminalPane = @fakeTabView.parent.createPane_ @fakeTerminalView, { name: 'Terminal' }

          @fakeFinderView   = new KDCustomHTMLView partial: splashs.getFileTree nickname, machineLabel
          @finderPane.addSubView @fakeFinderView, '.nfinder .jtreeview-wrapper'

        else
          @createNewTerminal { machine }
          @setActiveTabView @ideViews.first.tabView
          @forEachSubViewInIDEViews_ (pane) ->
            pane.isInitial = yes


  getMountedMachine: (callback = noop) ->

    KD.getSingleton('computeController').fetchMachines (err, machines) =>
      if err
        KD.showError "Couldn't fetch your VMs"
        return callback err, null

      KD.utils.defer =>
        @mountedMachine = m for m in machines when m.uid is @mountedMachineUId

        callback null, @mountedMachine


  mountMachineByMachineUId: (machineUId) ->

    computeController = KD.getSingleton 'computeController'
    container         = @getView()

    computeController.fetchMachines (err, machines) =>
      return KD.showError 'Something went wrong. Try again.'  if err

      callback = =>
        for machine in machines when machine.uid is machineUId
          machineItem = machine

        if machineItem
          {state} = machineItem.status
          machineId = machineItem._id

          if state is Running
            @mountMachine machineItem
          else

            unless @machineStateModal

              @createMachineStateModal {
                state, container, machineItem, initial: yes
              }

              if state is NotInitialized
                @machineStateModal.once 'MachineTurnOnStarted', =>
                  KD.getSingleton('mainView').activitySidebar.initiateFakeCounter()

          @prepareCollaboration()

          actionRequiredStates = [Pending, Stopping, Stopped, Terminating, Terminated]
          computeController.on "public-#{machineId}", (event) =>

            if event.status in actionRequiredStates

              KodingKontrol.dcNotification?.destroy()
              KodingKontrol.dcNotification = null

              machineItem.getBaseKite( no ).disconnect()

              unless @machineStateModal
                @createMachineStateModal { state, container, machineItem }

              else
                if event.status in actionRequiredStates
                  @machineStateModal.updateStatus event

        else
          @createMachineStateModal { state: 'NotFound', container }


      @appStorage = KD.getSingleton('appStorageController').storage 'IDE', '1.0.0'
      @appStorage.fetchStorage =>

        isOnboardingModalShown = @appStorage.getValue 'isOnboardingModalShown'

        callback()


  createMachineStateModal: (options = {}) ->

    { state, container, machineItem, initial } = options
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
      file     = FSHelper.createFileInstance { path }
      contents = ''

      @openFile file, contents


  createNewTerminal: (options) ->

    { machine, path } = options

    unless machine instanceof Machine
      machine = @mountedMachine

    if @workspaceData

      {rootPath, isDefault} = @workspaceData

      if rootPath and not isDefault
        path = rootPath

    # options can be an Event instance if the initiator is
    # a shortcut, and that can have a `path` property
    # which is an Array. This check is to make sure that the
    # `path` is always the one we send explicitly here - SY
    path = null  unless typeof path is 'string'

    @activeTabView.emit 'TerminalPaneRequested', options


  #absolete: 'ctrl - alt - b' shortcut was removed (bug #82710798)
  createNewBrowser: (url) ->

    url = ''  unless typeof url is 'string'

    @activeTabView.emit 'PreviewPaneRequested', url


  createNewDrawing: (paneHash) ->

    paneHash = null unless typeof paneHash is 'string'

    @activeTabView.emit 'DrawingPaneRequested', paneHash

  moveTab: (direction) ->

    return unless @activeTabView.parent?

    panel = @activeTabView.parent.parent
    return  unless panel instanceof KDSplitViewPanel

    targetOffset = @layout[direction](panel._layout.data.offset)
    return  unless targetOffset?

    targetPanel = @layoutMap[targetOffset]

    {pane} = @activeTabView.removePane @activeTabView.getActivePane(), yes, yes

    targetPanel.subViews.first.tabView.addPane pane
    @setActiveTabView targetPanel.subViews.first.tabView
    @doResize()

  moveTabUp: -> @moveTab('north')

  moveTabDown: -> @moveTab('south')

  moveTabLeft: -> @moveTab('west')

  moveTabRight: -> @moveTab('east')

  goToLeftTab: ->

    index = @activeTabView.getActivePaneIndex()
    return if index is 0

    @activeTabView.showPaneByIndex index - 1


  goToRightTab: ->

    index = @activeTabView.getActivePaneIndex()
    return if index is @activeTabView.length - 1

    @activeTabView.showPaneByIndex index + 1


  goToTabNumber: (keyEvent) ->

    keyEvent.preventDefault()
    keyEvent.stopPropagation()

    keyCodeMap    = [ 49..57 ]
    requiredIndex = keyCodeMap.indexOf keyEvent.keyCode

    @activeTabView.showPaneByIndex requiredIndex


  goToLine: ->

    @activeTabView.emit 'GoToLineRequested'


  closeTab: ->

    @activeTabView.removePane @activeTabView.getActivePane()


  registerIDEView: (ideView) ->

    @ideViews.push ideView

    ideView.on 'PaneRemoved', (pane) =>
      ideViewLength  = 0
      ideViewLength += ideView.tabView.panes.length  for ideView in @ideViews
      delete @generatedPanes[pane.view.hash]

      @statusBar.showInformation()  if ideViewLength is 0

    ideView.tabView.on 'PaneAdded', (pane) =>
      @registerPane pane

    ideView.on 'ChangeHappened', (change) =>
      @syncChange change  if @rtm


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
      for pane in ideView.tabView.panes
        view = pane.getSubViews().first
        if paneType
          if view.getOptions().paneType is paneType
            callback view
        else
          callback view


  updateSettings: (component, key, value) ->

    # TODO: Refactor this method by passing component type to helper method.
    Class  = if component is 'editor' then EditorPane else TerminalPane
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

    @autoSaveInterval = KD.utils.repeat 1000, =>
      @forEachSubViewInIDEViews_ 'editor', (ep) => ep.handleAutoSave()


  disableAutoSave: -> KD.utils.killRepeat @autoSaveInterval


  showShortcutsView: ->

    paneView = null

    @forEachSubViewInIDEViews_ (view) ->
      paneView = view.parent  if view instanceof ShortcutsView

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
      # FIXME: Take care of https.
      prefix      = "[#{@mountedMachineUId}]/home/#{KD.nick()}/Web/"
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
    menu     = new StatusBarMenu { paneType, paneView, delegate }

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

    @fileFinder = new FileFinder
    @fileFinder.once 'KDObjectWillBeDestroyed', => @fileFinder = null


  showContentSearch: ->

    return @contentSearch.findInput.setFocus()  if @contentSearch

    @contentSearch = new ContentSearch
    @contentSearch.once 'KDObjectWillBeDestroyed', => @contentSearch = null
    @contentSearch.once 'ViewNeedsToBeShown', (view) =>
      @activeTabView.emit 'ViewNeedsToBeShown', view


  createStatusBar: (splitViewPanel) ->

    splitViewPanel.addSubView @statusBar = new StatusBar


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

    @forEachSubViewInIDEViews_ 'terminal', (terminalPane) ->
      terminalPane.resurrect()

    unless @fakeViewsDestroyed
      @fakeFinderView?.destroy()
      @fakeTabView?.removePane_ @fakeTerminalPane
      @createNewTerminal { machine }
      @setActiveTabView @ideViews.first.tabView
      @fakeViewsDestroyed = yes


  toggleFullscreenIDEView: ->

    @activeTabView.parent.toggleFullscreen()


  doResize: ->

    @forEachSubViewInIDEViews_ (pane) ->
      {paneType} = pane.options
      switch paneType
        when 'terminal'
          {terminal} = pane.webtermView
          terminal.windowDidResize()  if terminal?
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
      if pane and pane.view instanceof TerminalPane
        pane.view.webtermView.terminal?.updateSize()


  removePaneFromTabView: (pane, shouldDetach = no) ->

    paneView = pane.parent
    tabView  = paneView.parent
    tabView.removePane paneView


  loadCollaborationFile: (fileId) ->

    return unless fileId

    @rtmFileId = fileId

    @rtm.getFile fileId

    @rtm.once 'FileLoaded', (doc) =>
      nickname = KD.nick()
      hostName = @collaborationHost

      @rtm.setRealtimeDoc doc

      @setCollaborativeReferences()

      if @amIHost
        @getView().setClass 'host'
      #   @changes.clear()
      #   @broadcastMessages.clear()

      isInList = no

      @participants.asArray().forEach (participant) =>
        isInList = yes  if participant.nickname is nickname

      if not isInList
        @addParticipant KD.whoami(), no

      @rtm.on 'CollaboratorJoined', (doc, participant) =>
        @handleParticipantAction 'join', participant

      @rtm.on 'CollaboratorLeft', (doc, participant) =>
        @handleParticipantAction 'left', participant

      @registerCollaborationSessionId()
      @bindRealtimeEvents()
      @listenPings()
      @rtm.isReady = yes
      @emit 'RTMIsReady'
      @resurrectSnapshot()

      unless @myWatchMap.values().length
        @listChatParticipants (accounts) =>
          accounts.forEach (account) =>
            {nickname} = account.profile
            @myWatchMap.set nickname, nickname

      if not @amIHost and @myWatchMap.values().indexOf(hostName) > -1
        hostSnapshot = @rtm.getFromModel "#{hostName}Snapshot"

        for key, change of hostSnapshot.values()
          @createPaneFromChange change

      KD.utils.repeat 60 * 55 * 1000, => @rtm.reauth()

      @finderPane.on 'ChangeHappened', @bound 'syncChange'

      unless @amIHost
        @makeReadOnly()  if @permissions.get(nickname) is 'read'


  setCollaborativeReferences: ->

    nickname           = KD.nick()
    myWatchMapName     = "#{nickname}WatchMap"
    mySnapshotName     = "#{nickname}Snapshot"
    defaultPermission  = default: 'edit'

    @participants      = @rtm.getFromModel 'participants'
    @changes           = @rtm.getFromModel 'changes'
    @permissions       = @rtm.getFromModel 'permissions'
    @broadcastMessages = @rtm.getFromModel 'broadcastMessages'
    @pingTime          = @rtm.getFromModel 'pingTime'
    @myWatchMap        = @rtm.getFromModel myWatchMapName
    @mySnapshot        = @rtm.getFromModel mySnapshotName

    @participants      or= @rtm.create 'list',   'participants', []
    @changes           or= @rtm.create 'list',   'changes', []
    @permissions       or= @rtm.create 'map',    'permissions', defaultPermission
    @broadcastMessages or= @rtm.create 'list',   'broadcastMessages', []
    @pingTime          or= @rtm.create 'string', 'pingTime'
    @myWatchMap        or= @rtm.create 'map',    myWatchMapName, {}

    initialSnapshot      = if @amIHost then @getWorkspaceSnapshot() else {}
    @mySnapshot        or= @rtm.create 'map',    mySnapshotName, initialSnapshot


  registerCollaborationSessionId: ->

    collaborators = @rtm.getCollaborators()

    for collaborator in collaborators when collaborator.isMe
      participants = @participants.asArray()

      for user, index in participants when user.nickname is KD.nick()
        newData = KD.utils.dict()

        newData[key] = value  for key, value of user

        newData.sessionId = collaborator.sessionId
        @participants.remove index
        @participants.insert index, newData


  addParticipant: (account) ->

    {hash, nickname} = account.profile
    @participants.push { nickname, hash }


  getWorkspaceSnapshot: ->

    panes = {}

    @forEachSubViewInIDEViews_ (pane) ->
      return  if not pane.serialize or (@isInSession and pane.isInitial)

      data = pane.serialize()
      panes[data.hash] =
        type    : 'NewPaneCreated'
        context : data

    return panes


  resurrectSnapshot: ->

    return  if @collaborationJustInitialized or @fakeTabView

    mySnapshot   = @mySnapshot.values().filter (item) -> return not item.isInitial
    hostSnapshot = @rtm.getFromModel("#{@collaborationHost}Snapshot")?.values()
    snapshot     = if hostSnapshot then mySnapshot.concat hostSnapshot else mySnapshot

    @forEachSubViewInIDEViews_ (pane) => @removePaneFromTabView pane

    for change in snapshot when change.context
      {paneType} = change.context

      if paneType is 'terminal'
        @setActiveTabView @ideViews.last.tabView
      else
        @setActiveTabView @ideViews.first.tabView

      @createPaneFromChange change


  syncChange: (change) ->

    {context} = change

    return  if not @rtm or not @rtm.isReady or not context

    {paneHash} = context
    nickname   = KD.nick()

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

        delete context.file?.content?

      @changes.push change

    switch change.type

      when 'NewPaneCreated'
        @mySnapshot.set paneHash, change  if paneHash

      when 'PaneRemoved'
        @mySnapshot.delete paneHash  if paneHash


  watchParticipant: (nickname) -> @myWatchMap.set nickname, nickname


  unwatchParticipant: (nickname) -> @myWatchMap.delete nickname


  bindRealtimeEvents: ->

    @rtm.bindRealtimeListeners @changes, 'list'
    @rtm.bindRealtimeListeners @broadcastMessages, 'list'
    @rtm.bindRealtimeListeners @myWatchMap, 'map'
    @rtm.bindRealtimeListeners @permissions, 'map'

    @rtm.on 'ValuesAddedToList', (list, event) =>

      [value] = event.values

      switch list
        when @changes           then @handleChange value
        when @broadcastMessages then @handleBroadcastMessage value

    @rtm.on 'ValuesRemovedFromList', (list, event) =>

      @handleChange event.values[0]  if list is @changes

    @rtm.on 'MapValueChanged', (map, event) =>

      if map is @myWatchMap
        @handleWatchMapChange event

      else if map is @permissions
        @handlePermissionMapChange event


  handlePermissionMapChange: (event) ->

    @chat.settingsPane.emit 'PermissionChanged', event

    {property, newValue} = event

    return  unless property is KD.nick()

    if      newValue is 'edit' then @makeEditable()
    else if newValue is 'read' then @makeReadOnly()


  handleWatchMapChange: (event) ->

    {property, newValue, oldValue} = event

    if newValue is property
      @statusBar.emit 'ParticipantWatched', property

    else unless newValue
      @statusBar.emit 'ParticipantUnwatched', property


  handleChange: (change) ->

    {context, origin, type} = change

    return if not context or not origin or origin is KD.nick()

    amIWatchingChangeOwner = @myWatchMap.keys().indexOf(origin) > -1

    if amIWatchingChangeOwner or type is 'CursorActivity'
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


  createPaneFromChange: (change) ->

    return unless @rtm

    {context} = change
    return unless context

    paneHash = context.paneHash or context.hash
    currentSnapshot = @getWorkspaceSnapshot()

    return  if currentSnapshot[paneHash]

    switch context.paneType
      when 'terminal'
        terminalOptions =
          machine  : @mountedMachine
          session  : context.session
          hash     : paneHash
          joinUser : @collaborationHost or KD.nick()

        @createNewTerminal terminalOptions

      when 'editor'
        {path}        = context.file
        file          = FSHelper.createFileInstance {path, machine : @mountedMachine}
        file.paneHash = paneHash

        content = @rtm.getFromModel(path)?.getText() or ''

        @openFile file, content, noop, no

      when 'drawing'
        @createNewDrawing paneHash

    unless @mySnapshot.get paneHash
      @mySnapshot.set paneHash, change


  handleParticipantAction: (actionType, changeData) ->

    KD.utils.wait 2000, =>
      participants  = @participants.asArray()
      {sessionId}   = changeData.collaborator
      targetUser    = null
      targetIndex   = null

      for participant, index in participants when participant.sessionId is sessionId
        targetUser  = participant.nickname
        targetIndex = index

      unless targetUser
        return warn 'Unknown user in collaboration, we should handle this case...'

      if actionType is 'join'
        @chat.emit 'ParticipantJoined', targetUser
        @statusBar.emit 'ParticipantJoined', targetUser
      else
        @chat.emit 'ParticipantLeft', targetUser
        @statusBar.emit 'ParticipantLeft', targetUser
        @removeParticipantCursorWidget targetUser

        # check the user is still at same index, so we won't remove someone else.
        user = @participants.get targetIndex

        if user.nickname is targetUser
          @participants.remove targetIndex
        else
          participants = @participants.asArray()
          for participant, index in participants when participant.nickname is targetUser
            @participants.remove index


  setRealTimeManager: (object) =>

    callback = =>
      object.rtm = @rtm
      object.emit 'RealTimeManagerSet'

    if @rtm?.isReady then callback() else @once 'RTMIsReady', => callback()


  getWorkspaceName: (callback) -> callback @workspaceData.name


  createChatPaneView: (channel) ->

    options = { @rtm, @isInSession }
    @getView().addSubView @chat = new ChatView options, channel
    @chat.show()

    @on 'RTMIsReady', =>
      @listChatParticipants (accounts) =>
        @chat.settingsPane.createParticipantsList accounts

      @statusBar.emit 'CollaborationStarted'

      {settingsPane} = @chat

      settingsPane.on 'ParticipantKicked', @bound 'handleParticipantKicked'
      settingsPane.updateDefaultPermissions()


  createChatPane: ->

    @startChatSession (err, channel) =>

      return KD.showError err  if err

      @createChatPaneView channel


  showChat: ->

    return @createChatPane()  unless @chat

    @chat.start()


  prepareCollaboration: ->

    @rtm        = new RealTimeManager
    {channelId} = @workspaceData

    @rtm.ready =>
      unless @workspaceData.channelId
        return @statusBar.share.show()

      @fetchSocialChannel (channel) =>
        @isRealtimeSessionActive channelId, (isActive) =>
          if isActive or @isInSession
            @startChatSession => @chat.showChatPane()
            @chat.hide()
            @statusBar.share.updatePartial 'Chat'

          @statusBar.share.show()


  createWorkspace: (options = {}) ->

    name         = options.name or 'My Workspace'
    rootPath     = "/home/#{KD.nick()}"
    {label, uid} = @mountedMachine

    return KD.remote.api.JWorkspace.create
      name         : name
      label        : options.label        or label
      machineUId   : options.machineUId   or uid
      machineLabel : options.machineLabel or label
      rootPath     : options.rootPath     or rootPath
      isDefault    : name is 'My Workspace'


  updateWorkspace: (options = {}) ->

    return KD.remote.api.JWorkspace.update @workspaceData._id, { $set : options }


  startChatSession: (callback) ->

    return if @workspaceData.isDummy
      @createWorkspace()
        .then (workspace) =>
          @workspaceData = workspace
          @initPrivateMessage callback
        .error callback

    channelId = @channelId or @workspaceData.channelId

    if channelId

      @fetchSocialChannel (channel) =>

        @createChatPaneView channel

        @isRealtimeSessionActive channelId, (isActive, file) =>

          if isActive
            @loadCollaborationFile file.result.items[0].id
            return @continuePrivateMessage callback

          @statusBar.share.show()
          @chat.emit 'CollaborationNotInitialized'

    else
      @initPrivateMessage callback


  stopChatSession: ->

    @chat.emit 'CollaborationEnded'
    @chat = null


  getRealTimeFileName: (id) ->

    unless id
      if @channelId          then id = @channelId
      else if @socialChannel then id = @socialChannel.id
      else
        return KD.showError 'social channel id is not provided'

    hostName = if @amIHost then KD.nick() else @collaborationHost

    return "#{hostName}.#{id}"


  continuePrivateMessage: (callback) ->

    @on 'RTMIsReady', =>
      @chat.emit 'CollaborationStarted'

      @listChatParticipants (accounts) =>
        @statusBar.emit 'ShowAvatars', accounts, @participants.asArray()

      callback()


  isRealtimeSessionActive: (id, callback) ->

    kallback = =>
      @rtm.once 'FileQueryFinished', (file) =>

        if file.result.items.length > 0
          callback yes, file
        else
          callback no

      @rtm.fetchFileByTitle @getRealTimeFileName id

    if @rtm then kallback()
    else
      @rtm = new RealTimeManager
      @rtm.ready => kallback()


  setSocialChannel: (channel) ->

    @socialChannel = channel

    @socialChannel.on 'AddedToChannel', (originOrAccount) =>

      kallback = (account) =>

        return  unless account

        {nickname} = account.profile
        @statusBar.createParticipantAvatar nickname, no
        @watchParticipant nickname

      if originOrAccount.constructorName
        KD.remote.cacheable originOrAccount.constructorName, originOrAccount.id, kallback
      else if 'string' is typeof originOrAccount
        KD.remote.cacheable originOrAccount, kallback
      else
        kallback originOrAccount


  initPrivateMessage: (callback) ->

    {message} = KD.singletons.socialapi
    nick      = KD.nick()

    message.initPrivateMessage
      body       : "@#{nick} initiated the IDE session."
      purpose    : "#{KD.utils.getCollaborativeChannelPrefix()}#{dateFormat 'HH:MM'}"
      recipients : [ nick ]
      payload    :
        'system-message' : 'initiate'
        collaboration    : yes
    , (err, channels) =>

      return callback err  if err or (not Array.isArray(channels) and not channels[0])

      [channel] = channels
      @setSocialChannel channel

      @updateWorkspace { channelId : channel.id }
        .then =>
          @workspaceData.channelId = channel.id
          callback null, channel
          @chat.ready => @chat.emit 'CollaborationNotInitialized'
        .error callback


  fetchSocialChannel: (callback) ->

    return callback @socialChannel  if @socialChannel

    id = @channelId or @workspaceData.channelId

    KD.singletons.socialapi.cacheable 'channel', id, (err, channel) =>
      return KD.showError err  if err

      @setSocialChannel channel

      callback @socialChannel


  deletePrivateMessage: (callback = noop) ->

    {channel}    = KD.getSingleton 'socialapi'
    {JWorkspace} = KD.remote.api

    options = channelId: @socialChannel.getId()
    channel.delete options, (err) =>

      return KD.showError err  if err

      @channelId = @socialChannel = null

      options = $unset: channelId: 1
      JWorkspace.update @workspaceData._id, options, (err) =>

        return KD.showError err  if err

        @workspaceData.channelId = null

        callback()


  # FIXME: This method is called more than once. It should cache the result and
  # return if result set exists.
  listChatParticipants: (callback) ->

    channelId = @socialChannel.getId()

    {socialapi} = KD.singletons
    socialapi.channel.listParticipants {channelId}, (err, participants) ->

      idList = participants.map ({accountId}) -> accountId
      query  = socialApiId: $in: idList

      KD.remote.api.JAccount.some query, {}
        .then callback


  startCollaborationSession: (callback) ->

    return callback msg : 'no social channel'  unless @socialChannel

    {message} = KD.singletons.socialapi
    nick      = KD.nick()

    message.sendPrivateMessage
      body       : "@#{nick} activated collaboration."
      channelId  : @socialChannel.id
      payload    :
        'system-message' : 'start'
        collaboration    : yes
    , callback

    @collaborationJustInitialized = yes

    @rtm.once 'FileCreated', (file) =>
      @loadCollaborationFile file.id

    @rtm.createFile @getRealTimeFileName()

    @setMachineSharingStatus on


  showEndCollaborationModal: (callback) ->

    modalOptions =
      title      : 'Are you sure?'
      content    : 'This will end your session and all participants will be removed from this session.'

    @showModal modalOptions, => @stopCollaborationSession callback


  stopCollaborationSession: (callback = noop) ->

    @chat.settingsPane.endSession.disable()

    return callback msg : 'no social channel'  unless @socialChannel

    {message} = KD.singletons.socialapi
    nick      = KD.nick()

    @broadcastMessages.push origin: KD.nick(), type: 'SessionEnded'

    @rtm.once 'FileDeleted', =>
      @statusBar.emit 'CollaborationEnded'
      @stopChatSession()
      @modal.destroy()
      @rtm.dispose()
      @rtm = null
      KD.utils.killRepeat @pingInterval
      KD.singletons.mainView.activitySidebar.emit 'ReloadMessagesRequested'
      @forEachSubViewInIDEViews_ 'editor', (ep) => ep.removeAllCursorWidgets()

    @mySnapshot.clear()
    @rtm.deleteFile @getRealTimeFileName()

    if @amIHost
      @setMachineSharingStatus off
      @deletePrivateMessage callback


  setMachineSharingStatus: (status) ->

    @listChatParticipants (accounts) =>
      @setMachineUser accounts, status


  setMachineUser: (accounts, share = yes, callback = noop) ->

    usernames = accounts.map (account) -> account.profile.nickname

    if @amIHost
      usernames = usernames.filter (username) -> username isnt KD.nick()

    return  unless usernames.length

    jMachine = @mountedMachine.getData()
    method   = if share then 'share' else 'unshare'
    jMachine[method] usernames, (err) =>

      return KD.showError err  if err

      kite   = @mountedMachine.getBaseKite()
      method = if share then 'klientShare' else 'klientUnshare'

      queue = usernames.map (username) ->
        ->
          kite[method] {username}
            .then -> queue.fin()
            .error (err) ->
              queue.fin()

              return  if err.message in [
                'user is already in the shared list.'
                'user is not in the shared list.'
              ]

              action = if share then 'added' else 'removed'
              KD.showError "#{username} couldn't be #{action} as an user"
              console.error err

      Bongo.dash queue, callback


  showModal: (modalOptions = {}, callback = noop) ->
    return  if @modal

    modalOptions.overlay  ?= yes
    modalOptions.blocking ?= no
    modalOptions.buttons or=
      Yes        :
        cssClass : 'modal-clean-green'
        callback : callback
      No         :
        cssClass : 'modal-cancel'
        callback : => @modal.destroy()

    ModalClass = if modalOptions.blocking then KDBlockingModalView else KDModalView

    @modal = new ModalClass modalOptions
    @modal.once 'KDObjectWillBeDestroyed', =>
      delete @modal


  handleBroadcastMessage: (data) ->

    {origin, type} = data

    return  if origin is KD.nick()

    switch type

      when 'SessionEnded'

        @showSessionEndedModal()

      when 'ParticipantWantsToLeave'

        @handleParticipantKicked data.origin

      when 'ParticipantKicked'

        return  unless data.origin is @collaborationHost

        if data.target is KD.nick()
          @removeMachineNode()
          @showKickedModal()
        else
          @handleParticipantKicked data.target


  unshareMachineAndKlient: (username, fetchUser = no) ->

    if fetchUser
      return KD.remote.cacheable username, (err, accounts) =>

        return KD.showError err  if err

        @setMachineUser accounts, no


    @listChatParticipants (accounts) =>

      for account in accounts when account.profile.nickname is username
        target = account

      @setMachineUser [target], no  if target


  showKickedModal: ->
    options        =
      title        : 'Your session has been closed'
      content      : "You have been removed from the session by @#{@collaborationHost}. - Please reload your browser -"
      blocking     : yes
      buttons      :
        ok         :
          title    : 'OK'
          callback : => @modal.destroy()

    @showModal options
    @quit()


  quit: ->

    KD.utils.killRepeat @autoSaveInterval
    KD.utils.killRepeat @pingInterval
    @rtm?.dispose()
    @rtm = null

    KD.singletons.router.handleRoute '/IDE'
    KD.singletons.appManager.quit this


  showSessionEndedModal: (content) ->

    content ?= "This session is ended by @#{@collaborationHost} You won't be able to access it anymore. - Please reload your browser -"

    options        =
      title        : 'Session ended'
      content      : content
      blocking     : yes
      buttons      :
        quit       :
          title    : 'LEAVE'
          callback : => @modal.destroy()

    @showModal options
    @removeMachineNode()
    @quit()


  handleParticipantLeaveAction: ->

    options   =
      title   : 'Are you sure?'
      content : "If you leave this session you won't be able to return back."

    @showModal options, =>
      @broadcastMessages.push origin: KD.nick(), type: 'ParticipantWantsToLeave'
      @stopChatSession()
      @modal.destroy()

      options = channelId: @socialChannel.getId()
      KD.singletons.socialapi.channel.leave options, (err) =>
        return KD.showError err  if err
        @setMachineUser [KD.whoami()], no, => @quit()


  removeMachineNode: ->

    KD.singletons.mainView.activitySidebar.removeMachineNode @mountedMachine


  handleParticipantKicked: (username) ->

    @chat.emit 'ParticipantLeft', username
    @statusBar.removeParticipantAvatar username
    @removeParticipantCursorWidget username


  getCollaborationData: (callback = noop) =>

    collaborationData =
      watchMap        : @myWatchMap?.values()
      amIHost         : @amIHost

    callback collaborationData


  kickParticipant: (account) ->

    return  unless @amIHost

    options      =
      channelId  : @socialChannel.id
      accountIds : [ account.socialApiId ]

    @setMachineUser [account], no, =>

      KD.singletons.socialapi.channel.kickParticipants options, (err, result) =>

        return KD.showError err  if err

        targetUser = account.profile.nickname
        message    =
          type     : 'ParticipantKicked'
          origin   : KD.nick()
          target   : targetUser

        @broadcastMessages.push message
        @handleParticipantKicked targetUser


  listenPings: ->

    pingInterval = 1000 * 5
    pongInterval = 1000 * 15
    diffInterval = KD.config.collaboration.timeout

    if @amIHost
      @pingInterval = KD.utils.repeat pingInterval, =>
        @pingTime.setText Date.now().toString()
    else
      @pingInterval = KD.utils.repeat pongInterval, =>
        lastPing = @pingTime.getText()

        return  if Date.now() - lastPing < diffInterval

        KD.remote.api.Collaboration.stop @rtmFileId, @workspaceData, (err) =>
          if err
          then console.warn err
          else
            KD.utils.killRepeat @pingInterval
            @stopCollaborationSession =>
              @quit()

              new KDNotificationView
                title    : "@#{@collaborationHost} has left the session."
                duration : 3000


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


module.exports = IDEAppController
