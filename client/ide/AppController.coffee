class IDEAppController extends AppController

  {
    Stopped, Running, NotInitialized, Terminated, Unknown, Pending,
    Starting, Building, Stopping, Rebooting, Terminating, Updating
  } = Machine.State


  KD.registerAppClass this,
    name         : 'IDE'
    behavior     : 'application'
    multiple     : yes
    preCondition :
      condition  : (options, cb) -> cb KD.isLoggedIn()
      failure    : (options, cb) ->
        KD.getSingleton('appManager').open 'IDE', conditionPassed : yes
        KD.showEnforceLoginModal()
    commands:
      'find file by name'   : 'showFileFinder'
      'search all files'    : 'showContentSearch'
      'split vertically'    : 'splitVertically'
      'split horizontally'  : 'splitHorizontally'
      'merge splitview'     : 'mergeSplitView'
      'preview file'        : 'previewFile'
      'save all files'      : 'saveAllFiles'
      'create new file'     : 'createNewFile'
      'create new terminal' : 'createNewTerminal'
      'create new browser'  : 'createNewBrowser'
      'create new drawing'  : 'createNewDrawing'
      'collapse sidebar'    : 'collapseSidebar'
      'expand sidebar'      : 'expandSidebar'
      'toggle sidebar'      : 'toggleSidebar'
      'close tab'           : 'closeTab'
      'go to left tab'      : 'goToLeftTab'
      'go to right tab'     : 'goToRightTab'
      'go to tab number'    : 'goToTabNumber'
      'fullscren ideview'   : 'toggleFullscreenIDEView'

    keyBindings: [
      { command: 'find file by name',   binding: 'ctrl+alt+o',       global: yes }
      { command: 'search all files',    binding: 'ctrl+alt+f',       global: yes }
      { command: 'split vertically',    binding: 'ctrl+alt+v',       global: yes }
      { command: 'split horizontally',  binding: 'ctrl+alt+h',       global: yes }
      { command: 'merge splitview',     binding: 'ctrl+alt+m',       global: yes }
      { command: 'preview file',        binding: 'ctrl+alt+p',       global: yes }
      { command: 'save all files',      binding: 'ctrl+alt+s',       global: yes }
      { command: 'create new file',     binding: 'ctrl+alt+n',       global: yes }
      { command: 'create new terminal', binding: 'ctrl+alt+t',       global: yes }
      { command: 'create new browser',  binding: 'ctrl+alt+b',       global: yes }
      { command: 'create new drawing',  binding: 'ctrl+alt+d',       global: yes }
      { command: 'toggle sidebar',      binding: 'ctrl+alt+k',       global: yes }
      { command: 'close tab',           binding: 'ctrl+alt+w',       global: yes }
      { command: 'go to left tab',      binding: 'ctrl+alt+[',       global: yes }
      { command: 'go to right tab',     binding: 'ctrl+alt+]',       global: yes }
      { command: 'go to tab number',    binding: 'mod+1',            global: yes }
      { command: 'go to tab number',    binding: 'mod+2',            global: yes }
      { command: 'go to tab number',    binding: 'mod+3',            global: yes }
      { command: 'go to tab number',    binding: 'mod+4',            global: yes }
      { command: 'go to tab number',    binding: 'mod+5',            global: yes }
      { command: 'go to tab number',    binding: 'mod+6',            global: yes }
      { command: 'go to tab number',    binding: 'mod+7',            global: yes }
      { command: 'go to tab number',    binding: 'mod+8',            global: yes }
      { command: 'go to tab number',    binding: 'mod+9',            global: yes }
      { command: 'fullscren ideview',   binding: 'mod+shift+enter',  global: yes }
    ]

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
            paneClass : IDE.IDEFilesTabView
          },
          {
            type      : 'custom'
            name      : 'editorPane'
            paneClass : IDE.IDEView
          }
        ]

    $('body').addClass 'dark' # for theming

    appView   = @getView()
    workspace = @workspace = new IDE.Workspace { layoutOptions }
    @ideViews = []

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

        {@finderPane} = @workspace.panel.getPaneByName 'filesPane'

        @bindRouteHandler()

    KD.singletons.appManager.on 'AppIsBeingShown', (app) =>

      return  unless app instanceof IDEAppController

      @setActivePaneFocus on

      # Temporary fix for IDE is not shown after
      # opening pages which uses old SplitView.
      # TODO: This needs to be fixed. ~Umut
      KD.singletons.windowController.notifyWindowResizeListeners()


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
    newIDEView     = new IDE.IDEView ideViewOptions
    @activeTabView = null

    ideView.detach()

    splitView   = new KDSplitView
      type      : type
      views     : [ null, newIDEView ]

    @registerIDEView newIDEView

    splitView.once 'viewAppended', ->
      splitView.panels.first.attach ideView
      splitView.panels[0] = ideView.parent
      splitView.options.views[0] = ideView

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

      @handleSplitMerge views, parent, parentSplitView, panelIndexInParent
      @doResize()

    splitView.merge()


  handleSplitMerge: (views, container, parentSplitView, panelIndexInParent) ->

    ideView = new IDE.IDEView createNewEditor: no
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
    {credential} = machineData.jMachine

    if credential is KD.nick()
      rootPath   = @workspaceData?.rootPath or null
    else
      rootPath   = "/home/#{credential}"

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
          splashs      = IDE.splashMarkups

          @fakeTabView      = @activeTabView
          @fakeTerminalView = new KDCustomHTMLView partial: splashs.getTerminal nickname
          @fakeTerminalPane = @fakeTabView.parent.createPane_ @fakeTerminalView, { name: 'Terminal' }

          @fakeFinderView   = new KDCustomHTMLView partial: splashs.getFileTree nickname, machineLabel
          @finderPane.addSubView @fakeFinderView, '.nfinder .jtreeview-wrapper'

        else
          @createNewTerminal machine
          @setActiveTabView @ideViews.first.tabView


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
    tabView.showPaneByName 'Dummy'

    @isSidebarCollapsed = yes

    tabView.on 'PaneDidShow', (pane) ->
      return if pane.options.name is 'Dummy'
      @expandSidebar()  if @isSidebarCollapsed


    # TODO: This will reactivated after release.
    # temporary fix. ~Umut

    # splitView.once 'PanelSetToFloating', =>
    #   floatedPanel._lastSize = desiredSize
    #   @getView().setClass 'sidebar-collapsed'
    #   @isSidebarCollapsed = yes
    #   KD.getSingleton("windowController").notifyWindowResizeListeners()

    # # splitView.setFloatingPanel 0, 39
    # tabView.showPaneByName 'Dummy'

    # tabView.on 'PaneDidShow', (pane) ->
    #   return if pane.options.name is 'Dummy'
    #   splitView.showPanel 0
    #   floatedPanel._lastSize = desiredSize

    # floatedPanel.on 'ReceivedClickElsewhere', ->
    #   KD.utils.defer ->
    #     splitView.setFloatingPanel 0, 39
    #     tabView.showPaneByName 'Dummy'


  expandSidebar: ->

    panel        = @workspace.getView()
    splitView    = panel.layout.getSplitViewByName 'BaseSplit'
    floatedPanel = splitView.panels.first
    filesPane    = panel.getPaneByName 'filesPane'

    splitView.resizePanel 250, 0
    @getView().unsetClass 'sidebar-collapsed'
    floatedPanel.unsetClass 'floating'
    @isSidebarCollapsed = no
    # filesPane.tabView.showPaneByIndex 0

    # floatedPanel._lastSize = 250
    # splitView.unsetFloatingPanel 0
    # filesPane.tabView.showPaneByIndex 0
    # floatedPanel.off 'ReceivedClickElsewhere'
    # @getView().unsetClass 'sidebar-collapsed'
    # @isSidebarCollapsed = no


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


  createNewTerminal: (machine, path, session, joinUser) ->

    machine = null  unless machine instanceof Machine

    if @workspaceData
      {rootPath, isDefault} = @workspaceData

      if rootPath and not isDefault
        path = rootPath

    @activeTabView.emit 'TerminalPaneRequested', machine, path, session, joinUser


  createNewBrowser: (url) ->

    url = ''  unless typeof url is 'string'

    @activeTabView.emit 'PreviewPaneRequested', url


  createNewDrawing: (paneHash) ->

    paneHash = null unless typeof paneHash is 'string'

    @activeTabView.emit 'DrawingPaneRequested', paneHash


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
      @syncChange change


  registerPane: (pane) ->

    {view} = pane
    unless view?.hash?
      return warn 'view.hash not found, returning'

    @generatedPanes or= {}
    @generatedPanes[view.hash] = yes

    view.on 'ChangeHappened', (change) =>
      @syncChange change


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
    Class  = if component is 'editor' then IDE.EditorPane else IDE.TerminalPane
    method = "set#{key.capitalize()}"

    @forEachSubViewInIDEViews_ (view) ->
      if view instanceof Class
        if component is 'editor'
          view.aceView.ace[method] value
        else
          view.webtermView.updateSettings()


  showShortcutsView: ->

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
      ace.once 'FileContentSynced', ->
        ace.removeModifiedFromTab editorPane.aceView

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
    menu     = new IDE.StatusBarMenu { paneType, paneView, delegate }

    ideView.menu = menu

    menu.on 'viewAppended', ->
      if paneType is 'editor' and paneView
        {syntaxSelector} = menu
        {ace}            = paneView.aceView

        syntaxSelector.select.setValue ace.getSyntax()
        syntaxSelector.on 'SelectionMade', (value) =>
          ace.setSyntax value


  showFileFinder: ->

    return @fileFinder.input.setFocus()  if @fileFinder

    @fileFinder = new IDE.FileFinder
    @fileFinder.once 'KDObjectWillBeDestroyed', => @fileFinder = null


  showContentSearch: ->

    return @contentSearch.findInput.setFocus()  if @contentSearch

    @contentSearch = new IDE.ContentSearch
    @contentSearch.once 'KDObjectWillBeDestroyed', => @contentSearch = null
    @contentSearch.once 'ViewNeedsToBeShown', (view) =>
      @activeTabView.emit 'ViewNeedsToBeShown', view


  createStatusBar: (splitViewPanel) ->

    splitViewPanel.addSubView @statusBar = new IDE.StatusBar


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
      @createNewTerminal machine
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


  loadCollaborationFile: (fileId) ->

    return unless fileId

    @rtm.getFile fileId

    @rtm.once 'FileLoaded', (doc) =>
      @rtm.setRealtimeDoc doc
      nickname           = KD.nick()
      myWatchMapName     = "#{nickname}WatchMap"
      mySnapshotName     = "#{nickname}Snapshot"

      @participants      = @rtm.getFromModel 'participants'
      @changes           = @rtm.getFromModel 'changes'
      @broadcastMessages = @rtm.getFromModel 'broadcastMessages'
      @myWatchMap        = @rtm.getFromModel myWatchMapName
      @mySnapshot        = @rtm.getFromModel mySnapshotName

      @participants      or= @rtm.create 'list', 'participants', []
      @changes           or= @rtm.create 'list', 'changes', []
      @broadcastMessages or= @rtm.create 'list', 'broadcastMessages', []
      @myWatchMap        or= @rtm.create 'map',  myWatchMapName, {}
      @mySnapshot        or= @rtm.create 'map',  mySnapshotName, @createWorkspaceSnapshot()

      # if @amIHost
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

      @registerParticipantSessionId()
      @listenChangeEvents()
      @rtm.isReady = yes
      @emit 'RTMIsReady'
      @resurrectSnapshot()

      KD.utils.repeat 60 * 55 * 1000, => @rtm.reauth()


  registerParticipantSessionId: ->

    collaborators = @rtm.getCollaborators()

    for collaborator in collaborators when collaborator.isMe
      participants = @participants.asArray()

      for user, index in participants when user.nickname is KD.nick()
        user.sessionId = collaborator.sessionId
        @participants.remove index
        @participants.insert index, user


  addParticipant: (account) ->

    {hash, nickname} = account.profile
    @participants.push { nickname, hash }


  createWorkspaceSnapshot: ->

    panes = {}

    @forEachSubViewInIDEViews_ (pane) ->
      return unless pane.serialize

      if pane.options.paneType is 'editor'
        data = pane.serialize()
        panes[data.hash] = data
      else
        data = pane.serialize()
        panes[data.hash] = data

    return panes


  resurrectSnapshot: ->

    for change in @mySnapshot.values() when change.context
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
        @mySnapshot.set paneHash, change

      when 'PaneRemoved'
        @mySnapshot.delete paneHash


  watchParticipant: (nickname) -> @myWatchMap.set nickname, nickname


  unwatchParticipant: (nickname) -> @myWatchMap.delete nickname


  listenChangeEvents: ->

    @rtm.bindRealtimeListeners @changes, 'list'
    @rtm.bindRealtimeListeners @broadcastMessages, 'list'

    @rtm.on 'ValuesAddedToList', (list, event) =>

      [value] = event.values

      switch list

        when @changes
          @handleChange value

        when @broadcastMessages
          @handleBroadcastMessage value

    @rtm.on 'ValuesRemovedFromList', (list, event) =>

      @handleChange event.values[0]  if list is @changes


  handleChange: (change) ->

    {context, origin, type} = change

    return if not context or not origin or origin is KD.nick()

    amIWatchingChangeOwner = @myWatchMap.keys().length is 0 or origin in @myWatchMap.keys()

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

    {context} = change
    return unless context

    switch context.paneType
      when 'terminal'
        @createNewTerminal @mountedMachine, null, context.session, @collaborationHost or KD.nick()

      when 'editor'
        {path}        = context.file
        file          = FSHelper.createFileInstance path
        file.paneHash = context.paneHash

        content = @rtm.getFromModel(path)?.getText() or ''

        @openFile file, content, noop, no

      when 'drawing'
        @createNewDrawing context.paneHash


    {paneHash} = context

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
    @getView().addSubView @chat = new IDE.ChatView options, channel
    @chat.show()

    @on 'RTMIsReady', =>
      @listChatParticipants (accounts) =>
        @chat.settingsPane.createParticipantsList accounts

      @statusBar.emit 'CollaborationStarted'

      @chat.settingsPane.on 'ParticipantKicked', @bound 'handleParticipantKicked'


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

    @rtm.once 'FileQueryFinished', (file) =>

      if file.result.items.length > 0
        callback yes, file
      else
        callback no

    @rtm.fetchFileByTitle @getRealTimeFileName id


  initPrivateMessage: (callback) ->

    {message} = KD.singletons.socialapi
    nick      = KD.nick()

    message.initPrivateMessage
      body       : "@#{nick} initiated the IDE session."
      purpose    : "IDE #{dateFormat 'HH:MM'}"
      recipients : [ nick ]
      payload    :
        'system-message' : 'initiate'
        collaboration    : yes
    , (err, channels) =>

      return callback err  if err or (not Array.isArray(channels) and not channels[0])

      [channel]      = channels
      @socialChannel = channel

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

      @socialChannel = channel

      callback @socialChannel


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

    @rtm.once 'FileCreated', (file) =>
      @loadCollaborationFile file.id

    @rtm.createFile @getRealTimeFileName()

    @setMachineSharingStatus on


  stopCollaborationSession: (callback) ->

    modalOptions =
      title      : 'Are you sure?'
      content    : 'This will end your session and all participants will be removed from this session.'

    @showModal modalOptions, =>

      @chat.settingsPane.endSession.disable()

      return callback msg : 'no social channel'  unless @socialChannel

      {message} = KD.singletons.socialapi
      nick      = KD.nick()

      message.sendPrivateMessage
        body       : "@#{nick} stopped collaboration. Access to the shared assets is no more possible. However you can continue chatting here with your peers."
        channelId  : @socialChannel.id
        payload    :
           'system-message' : 'stop'
           collaboration    : yes
      , callback

      @broadcastMessages.push origin: KD.nick(), type: 'SessionEnded'

      @rtm.once 'FileDeleted', =>
        @statusBar.emit 'CollaborationEnded'
        @chat.emit 'CollaborationEnded'
        @modal.destroy()
        KD.singletons.mainView.activitySidebar.emit 'ReloadMessagesRequested'

      @rtm.deleteFile @getRealTimeFileName()

      @setMachineSharingStatus off


  setMachineSharingStatus: (status) ->

    @listChatParticipants (accounts) =>
      @setMachineUser accounts, status


  setMachineUser: (accounts, share = yes, callback = noop) ->

    return  unless @mountedMachine.jMachine.credential is KD.nick()

    usernames = accounts.map (account) -> account.profile.nickname
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

        @unshareMachineAndKlient data.origin  if @amIHost

      when 'ParticipantKicked'

        return  unless data.origin is @collaborationHost

        if data.target is KD.nick()
          KD.getSingleton('router').handleRoute '/IDE'
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
      title        : 'Session ended'
      content      : "You have been removed from the session by @#{@collaborationHost}."
      blocking     : yes
      buttons      :
        ok         :
          title    : 'OK'
          callback : => @modal.destroy()

    @showModal options


  showSessionEndedModal: ->

    options        =
      title        : 'Session Ended'
      content      : "This session ended by @#{@collaborationHost} You won't be able to access it anymore."
      blocking     : yes
      buttons      :
        quit       :
          title    : 'LEAVE'
          callback : =>
            @modal.destroy()
            KD.singletons.router.handleRoute '/IDE'

    @showModal options
    @removeMachineNode()


  handleParticipantLeaveAction: ->

    options   =
      title   : 'Are you sure'
      content : "If you leave this session you won't be able to return this session."

    @showModal options, =>
      @broadcastMessages.push origin: KD.nick(), type: 'ParticipantWantsToLeave'
      @removeMachineNode()
      @modal.destroy()
      KD.singletons.mainView.activitySidebar.emit 'ReloadMessagesRequested'
      KD.singletons.router.handleRoute '/IDE'


  removeMachineNode: ->

    KD.singletons.mainView.activitySidebar.removeMachineNode @mountedMachine


  handleParticipantKicked: (username) ->

    if @amIHost

      message  =
        type   : 'ParticipantKicked'
        origin : KD.nick()
        target : username

      @broadcastMessages.push message
      @unshareMachineAndKlient username, yes

    @chat.emit 'ParticipantLeft', username
    @statusBar.emit 'ParticipantLeft', username
  kickParticipant: (account) ->

    options      =
      channelId  : @socialChannel.id
      accountIds : [ account.socialApiId ]

    KD.singletons.socialapi.channel.kickParticipants options, (err, result) =>

      return KD.showError err  if err

      @socialChannel.emit 'RemovedFromChannel', account
