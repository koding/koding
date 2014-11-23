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
    panel        = @workspace.getView()
    filesPane    = panel.getPaneByName 'filesPane'
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

          @prepareCollaboration___()

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
      path     = "localfile:/Untitled-#{newFileSeed++}.txt"
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
    @statusBar.on 'ParticipantsModalRequired', @bound 'showParticipantsModal'

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


  prepareCollaboration: ->
    machine         = @mountedMachine
    {workspaceData} = this
    @rtm = rtm      = new RealTimeManager

    rtm.auth()

    rtm.once 'ClientAuthenticated', =>
      hostName = if @amIHost then KD.nick() else @collaborationHost
      title    = "#{hostName}.#{machine.slug}.#{workspaceData.slug}"

      rtm.fetchFileByTitle title

      rtm.once 'FileQueryFinished', (file) =>
        {result} = file
        return if result.selfLink.indexOf(title) is -1

        if result.items.length > 0
          @loadCollaborationFile file.result.items.first.id
        else if @amIHost
          rtm.createFile title
          rtm.once 'FileCreated', (file) =>
            @loadCollaborationFile file.result.id


  loadCollaborationFile: (fileId) ->
    return unless fileId

    @rtm.getFile fileId

    @rtm.once 'FileLoaded', (doc) =>
      @rtm.setRealtimeDoc doc
      nickname      = KD.nick()
      @participants = @rtm.getFromModel 'participants'
      @changes      = @rtm.getFromModel 'changes'

      unless @participants
        @participants = @rtm.create 'list', 'participants', []

      unless @changes
        @changes = @rtm.create 'list', 'changes', []

      isInList = no

      @participants.asArray().forEach (participant) =>
        isInList = yes  if participant.nickname is nickname

      if not isInList
        log 'acetz: I am not in the participants list, adding myself'
        @addParticipant()
      else
        log 'acetz: I am already in participants lists'

      log 'acetz: participants:', @participants.asArray()


      @rtm.on 'CollaboratorJoined', (doc, participant) =>
        @handleParticipantAction 'join', participant

      @rtm.on 'CollaboratorLeft', (doc, participant) =>
        @handleParticipantAction 'left', participant

      @registerParticipantSessionId()
      @listenChangeEvents()
      @rtm.isReady = yes
      @emit 'RTMIsReady'

      KD.utils.repeat 60 * 55 * 1000, => @rtm.reauth()


  registerParticipantSessionId: ->
    collaborators = @rtm.getCollaborators()

    for collaborator in collaborators when collaborator.isMe
      participants = @participants.asArray()

      for user, index in participants when user.nickname is KD.nick()
        user.sessionId = collaborator.sessionId
        @participants.remove index
        @participants.insert index, user


  addParticipant: ->
    {hash, nickname} = KD.whoami().profile

    @participants.push { nickname, hash }

    @rtm.create 'map', "#{nickname}Snapshot", @createWorkspaceSnapshot()

    log 'acetz: participant added:', nickname


  createWorkspaceSnapshot: ->
    panes = {}

    @forEachSubViewInIDEViews_ (pane) ->
      return unless pane.serialize

      if pane.options.paneType is 'editor'
        unless pane.file.path is 'localfile:/Untitled.txt'
          data = pane.serialize()
          panes[data.hash] = data
      else
        data = pane.serialize()
        panes[data.hash] = data

    return panes


  syncChange: (change) ->
    {context} = change

    return  if not @rtm or not @rtm.isReady or not context

    {paneHash} = context
    nickname   = KD.nick()
    map        = @rtm.getFromModel "#{nickname}Snapshot"
    changes    = @rtm.getFromModel 'changes'


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
          string.setText content

        delete context.file?.content?


      changes.push change

    return  unless map

    switch change.type

      when 'NewPaneCreated'
        map.set paneHash, change

      when 'PaneRemoved'
        map.delete paneHash


  watchParticipant: (targetParticipant) ->
    # TODO: Add presence check before watching user.
    target   = targetParticipant.nickname
    nickname = KD.nick()
    mapName  = "#{nickname}WatchMap"

    map = @rtm.getFromModel mapName

    if map
      if map.get target
        map.delete target
      else
        map.set target, target
    else
      map = @rtm.create 'map', mapName
      map.set target, target


  showParticipantsModal: ->
    host  = @collaborationHost or KD.nick()
    modal = new IDE.ParticipantsModal { @participants, @rtm, host }

    modal.on 'ParticipantWatchRequested', (participant) =>
      @watchParticipant participant


  listenChangeEvents: ->
    @changes = @rtm.getFromModel 'changes'
    @changes?.clear()  if @amIHost

    @rtm.bindRealtimeListeners @changes, 'list'

    @rtm.on 'ValuesAddedToList', (list, value) =>
      @handleChange value.values[0]  if list is @changes

    @rtm.on 'ValuesRemovedFromList', (list, value) =>
      @handleChange value.values[0]  if list is @changes


  handleChange: (change) ->
    {context, origin, type} = change
    myWatchMap = @rtm.getFromModel "#{KD.nick()}WatchMap"

    return if not context or not origin or origin is KD.nick()

    amIWatchingChangeOwner = not myWatchMap or myWatchMap.keys().length is 0 or origin in myWatchMap.keys()

    log 'change arrived', type

    if amIWatchingChangeOwner
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
        {path}  = context.file
        file    = FSHelper.createFileInstance path

        content = if path.indexOf('localfile:/') is -1
        then @rtm.getFromModel(path).getText()
        else ''

        @openFile file, content, noop, no

      when 'drawing'
        @createNewDrawing context.paneHash


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
      else
        @chat.emit 'ParticipantLeft', targetUser

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


  createChatPaneView: (channel) ->

    @getView().addSubView @chat = new IDE.ChatView { @rtm }, channel
    @chat.show()

    @once 'RTMIsReady', => @chat.settingsPane.createParticipantsList()


  createChatPane: ->

    @startChatSession (err, channel) =>

      return KD.showError err  if err

      @createChatPaneView channel


  showChat: ->

    return @createChatPane()  unless @chat

    @chat.show()


  prepareCollaboration___: ->

    @rtm        = new RealTimeManager
    {channelId} = @workspaceData

    @rtm.ready => @statusBar.share.show()


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

    KD.remote.api.JWorkspace.update @workspaceData._id, { $set : options }


  startChatSession: (callback) ->

    return if @workspaceData.isDummy
      @createWorkspace()
        .then (workspace) =>
          @workspaceData = workspace
          @initPrivateMessage callback
        .error callback

    channelId = @privateMessageId or @workspaceData.channelId

    if channelId

      @fetchSocialChannel (channel) =>

        @createChatPaneView channel

        @isRealtimeSessionActive channelId, (isActive) =>

          return @continuePrivateMessage callback  if isActive

          @statusBar.share.show()
          log 'start collaboration'

    else
      @initPrivateMessage callback

  getRealTimeFileName: (id) ->

    unless id
      if @privateMessageId   then id = @privateMessageId
      else if @socialChannel then id = @socialChannel.id
      else
        return KD.showError 'social channel id is not provided'

    hostName = if @amIHost then KD.nick() else @collaborationHost
    return "#{hostName}.#{id}"


  continuePrivateMessage: (callback) ->

    log 'continuePrivateMessage'
    @chat.emit 'CollaborationStarted'
    @once 'RTMIsReady', =>
      @statusBar.emit 'ShowAvatars', @participants.asArray()


  isRealtimeSessionActive: (id, callback) ->

    @rtm.once 'FileQueryFinished', (file) =>

      if file.result.items.length > 0
        log 'file found'
        callback yes
        @loadCollaborationFile file.result.items[0].id
      else
        log 'file not found'
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
        .error callback


  fetchSocialChannel: (callback) ->

    return callback @socialChannel  if @socialChannel

    query = id: @privateMessageId or @workspaceData.channelId

    KD.singletons.socialapi.channel.byId query, (err, channel) =>
      return KD.showError err  if err

      @socialChannel = channel


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
      log 'file created', file
      @chat.emit 'CollaborationStarted'

    @rtm.createFile @getRealTimeFileName()


  stopCollaborationSession: (callback) ->

    return callback msg : 'no social channel'  unless @socialChannel

    {message} = KD.singletons.socialapi
    nick      = KD.nick()

    message.sendPrivateMessage
      body       : "@#{nick} stopped collaboration. Access to the shared assets is no more possible."
      channelId  : @socialChannel.id
      payload    :
         'system-message' : 'stop'
         collaboration    : yes
    , callback

    @rtm.deleteFile @getRealTimeFileName()

    @rtm.once 'FileDeleted', =>
      log 'file deleted'
