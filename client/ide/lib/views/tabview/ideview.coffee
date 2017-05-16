$                     = require 'jquery'
kd                    = require 'kd'
nick                  = require 'app/util/nick'
FSFile                = require 'app/util/fs/fsfile'
KDView                = kd.View
FSHelper              = require 'app/util/fs/fshelper'
IDEHelpers            = require '../../idehelpers'
KDModalView           = kd.ModalView
IDEEditorPane         = require '../../workspace/panes/ideeditorpane'
IDETailerPane         = require '../../workspace/panes/idetailerpane'
KDContextMenu         = kd.ContextMenu
KDTabPaneView         = kd.TabPaneView
IDEDrawingPane        = require '../../workspace/panes/idedrawingpane'
IDETerminalPane       = require '../../workspace/panes/ideterminalpane'
generatePassword      = require 'app/util/generatePassword'
ProximityNotifier     = require './splithandleproximitynotifier'
IDEWorkspaceTabView   = require '../../workspace/ideworkspacetabview'
IDEApplicationTabView = require './ideapplicationtabview.coffee'
showError             = require 'app/util/showError'
Tracker               = require 'app/util/tracker'
ContentModal          = require 'app/components/contentModal'

HANDLE_PROXIMITY_DISTANCE   = 100
DEFAULT_SESSION_NAME_LENGTH = 24


module.exports = class IDEView extends IDEWorkspaceTabView


  constructor: (options = {}, data) ->

    options.tabViewClass     = IDEApplicationTabView
    options.createNewEditor ?= yes
    options.bind             = 'dragover drop'
    options.addSplitHandlers ?= yes

    super options, data

    @setHash()

    @openFiles = []
    @bindListeners()


  bindListeners: ->

    @on 'PlusHandleClicked',        @bound 'createPlusContextMenu'
    @on 'CloseHandleClicked',       @bound 'closeSplitView'
    @on 'FullscreenHandleClicked',  @bound 'toggleFullscreen'
    @on 'IDETabMoved',              @bound 'handleTabMoved'
    @on 'NewSplitViewCreated',      @bound 'handleSplitViewCreated'
    @on 'SplitViewMerged',          @bound 'handleSplitViewMerged'
    @on 'CloseFullScreen',          @bound 'handleCloseFullScreen'

    @on 'RemoveSplitRegions', => @tabView.removeSplitRegions()

    @tabView.on 'MachineTerminalRequested', @bound 'openMachineTerminal'
    @tabView.on 'TerminalPaneRequested',    @bound 'createTerminal'
    # obsolete: 'preview file' feature was removed (bug #82710798)
    @tabView.on 'PreviewPaneRequested',     (url) -> global.open "http://#{url}"
    @tabView.on 'DrawingPaneRequested',     @bound 'createDrawingBoard'
    @tabView.on 'ViewNeedsToBeShown',       @bound 'showView'
    @tabView.on 'TabNeedsToBeClosed',       @bound 'closeTabByFile'
    @tabView.on 'GoToLineRequested',        @bound 'goToLine'

    @tabView.on 'CloseRequested', (pane) =>
      askforsave = no
      @tabView.removePane pane.parent, null , no, askforsave

    @tabView.on 'FileNeedsToBeOpened', (file, contents, callback, emitChange, isActivePane) =>
      @closeUntitledFileIfNotChanged()
      file.initialContents = contents
      @openFile file, contents, callback, emitChange, isActivePane

    @tabView.on 'FileNeedsToBeTailed', @bound 'tailFile'

    @tabView.on 'PaneDidShow', =>
      { frontApp } = kd.singletons.appManager
      @updateStatusBar()
      frontApp?.writeSnapshot?()
      @focusTab()  if frontApp?.isTabViewFocused? @tabView

    @tabView.on 'PaneAdded', (pane) =>
      pane.tabHandle.setClass 'focus'

      { addSplitHandlers } = @getOptions()

      @ensureSplitHandlers()  if addSplitHandlers

      { tabHandle, view } = pane
      { options }  = view
      { paneType } = options


      switch paneType
        when 'editor'
          tabHandle.enableContextMenu()
          tabHandle.on 'RenamingRequested', (newTitle) =>
            pane.view.file.rename newTitle, (err) =>
              if err then @notify null, null, err

              pane.view.file.emit 'FilePathChanged', newTitle
          tabHandle.makeEditable()

        when 'terminal'
          tabHandle.enableContextMenu()

          webtermCallback = @lazyBound 'handleWebtermCreated', pane
          view.ready webtermCallback

          handleCallback = @lazyBound 'handleTerminalRenamingRequested', tabHandle
          tabHandle.on 'RenamingRequested', handleCallback

          tabHandle.makeEditable()


    @tabView.on 'PaneRemoved', ({ pane, handle }) =>
      { view } = pane
      { options : { paneType } } = view
      handle.off 'RenamingRequested'  if paneType in ['terminal', 'editor']
      view.webtermView.off 'click', @bound 'click'  if paneType is 'terminal'


    # This is a custom event for IDEApplicationTabView
    # to distinguish between user actions and programmed actions
    @tabView.on 'PaneRemovedByUserAction', (pane) =>
      { view } = pane

      if view instanceof IDETerminalPane
        sessionId = view.session or view.webtermView.sessionId
        @terminateSession @mountedMachine, sessionId

      unless @tabView.askForSaveModal
        @handleCloseSplitView pane


  handleCloseSplitView: (pane) ->

    { tabHandle } = pane

    appStorage = kd.getSingleton('appStorageController').storage 'Ace', '1.0.1'
    paneLength = tabHandle.getDelegate().panes.length

    return  if paneLength >= 1  # remove pane when there is only one pane left

    appStorage.ready =>

      if not appStorage.getValue 'IsAutoRemovePaneSuggested'
        appStorage.setValue 'IsAutoRemovePaneSuggested', yes
        return @showSuggestAutoRemovePaneModal()

      @closeSplitView()  if appStorage.getValue 'enableAutoRemovePane'


  showSuggestAutoRemovePaneModal: ->

    { frontApp } = kd.singletons.appManager

    modal = new ContentModal
      width         : 600
      title         : 'Remove Pane'
      cssClass      : 'content-modal'
      content       : '''
        <h>Would you like us to remove the pane when there are no tabs left?</h>
        <p>You can always change this setting on preferences.</p>
      '''
      overlay       : yes
      buttons       :
        'No'        :
          title     : 'No'
          style     : 'solid medium'
          callback  : -> modal.destroy()
        'Yes'       :
          title     : 'Yes'
          style     : 'solid medium'
          callback  : =>
            frontApp.settingsPane.emit 'EnableAutoRemovePane'
            @closeSplitView()
            modal.destroy()


  createSplitHandle = (type) ->

    handle = new kd.CustomHTMLView
      cssClass : "split-handle #{type}-split-handle"
      partial  : '<span class="icon"></span>'

    return handle


  ensureSplitHandlers: ->

    return # Disable this feature for now, see #106093732

    @verticalSplitHandle?.destroy()

    @tabView.addSubView @verticalSplitHandle = createSplitHandle 'vertical'
    @verticalSplitHandle.on 'click', @lazyBound 'emit', 'VerticalSplitHandleClicked'

    notifier = setupSplitHandleNotifier @verticalSplitHandle
    @on 'KDObjectWillBeDestroyed', notifier.bound 'destroy'

    @horizontalSplitHandle?.destroy()

    @tabView.addSubView @horizontalSplitHandle = createSplitHandle 'horizontal'
    @horizontalSplitHandle.on 'click', @lazyBound 'emit', 'HorizontalSplitHandleClicked'

    notifier = setupSplitHandleNotifier @horizontalSplitHandle
    @on 'KDObjectWillBeDestroyed', notifier.bound 'destroy'


  createPane_: (view, paneOptions, paneData) ->

    if not view or not paneOptions
      return  throw new Error 'Missing argument for createPane_ helper'

    unless view instanceof KDView
      return  throw new Error 'View must be an instance of KDView'

    if view instanceof IDEEditorPane
      paneOptions.name = @trimUntitledFileName paneOptions.name

    pane = new KDTabPaneView paneOptions, paneData
    pane.addSubView view
    pane.view = view

    @tabView.addPane pane, paneOptions.isActivePane

    pane.once 'KDObjectWillBeDestroyed', => @handlePaneRemoved pane

    if view instanceof IDETailerPane
      pane.tabHandle.addSubView new kd.CustomHTMLView
        tagName  : 'span'
        cssClass : 'tail-icon'

    return pane


  trimUntitledFileName: (name) ->

    untitledNameRegex = /Untitled[0-9\-]*.txt/
    matchedPattern    = untitledNameRegex.exec name

    return  if matchedPattern then matchedPattern.first else name


  createEditor: (file, content, callback = kd.noop, emitChange = yes, isActivePane) ->

    unless file # create dummy file and pass machine to that file
      path    = @getDummyFilePath()
      machine = kd.singletons.appManager.getFrontApp().mountedMachine
      file    = FSHelper.createFileInstance { path, machine }

    # we need to show a notification that file is read-only or not accessible
    # only if it is opened by user action
    # we use emitChange to detect this case for now
    notifyIfNoPermissions = emitChange

    if file.isDummyFile()
      return @createEditorAfterFileCheck file, content, callback, emitChange, no, isActivePane

    file.fetchPermissions (err, result) =>

      return showError err  if err

      { readable, writable } = result
      if notifyIfNoPermissions and not readable
        IDEHelpers.showFileAccessDeniedError()
        return callback()

      @createEditorAfterFileCheck file, content, callback, emitChange, not writable, isActivePane


  createEditorAfterFileCheck: (file, content, callback, emitChange, isReadOnly, isActivePane) ->

    content     = content or ''
    ideViewHash = @hash
    editorPane  = new IDEEditorPane { ideViewHash, file, content, delegate: this }

    paneOptions =
      name          : file.name
      editor        : editorPane
      aceView       : editorPane.aceView
      isActivePane  : isActivePane

    editorPane.on 'ShowMeAsActive', => @switchToEditorTabByFile file

    editorPane.once 'EditorIsReady', =>
      ace        = editorPane.getAce()
      appManager = kd.getSingleton 'appManager'

      if file.isDummyFile()
        cb = kd.utils.debounce 1200, => @emit 'UpdateWorkspaceSnapshot'
        ace.on 'FileContentChanged', cb

      ace.on 'ace.change.cursor', (cursor) ->
        appManager.tell 'IDE', 'updateStatusBar', 'editor', { file, cursor }

      ace.on 'FindAndReplaceViewRequested', (withReplaceMode) ->
        appManager.tell 'IDE', 'showFindReplaceView', withReplaceMode



      ace.editor.scrollToRow 0
      editorPane.goToLine 1

      notifyIfNoPermissions = emitChange

      if isReadOnly
        editorPane.makeReadOnly()
        editorPane.isFileReadonly = yes
        IDEHelpers.showFileReadOnlyNotification()  if notifyIfNoPermissions

      callback editorPane

    @createPane_ editorPane, paneOptions, file

    if emitChange
      change        =
        context     :
          file      :
            content : content
            path    : file.path
            machine :
              uid   : file.machine.uid

      @emitChange editorPane, change

    @emit 'NewEditorPaneCreated', editorPane

    return editorPane


  tailFile: (options) ->

    { file, content, callback, emitChange, description, isActivePane, tailOffset } = options

    callback   ?= kd.noop
    emitChange ?= yes

    file.fetchPermissions (err, result) =>

      return showError err  if err

      { readable, writable } = result
      if not readable
        IDEHelpers.showFileAccessDeniedError()
        return callback()

      content   or= ''
      tailerPane  = new IDETailerPane {
        file, content, description, delegate: this,
        ideViewHash: @hash, tailOffset
      }

      paneOptions = {
        name: file.name
        isActivePane
      }

      tailerPane.once 'EditorIsReady', ->
        callback tailerPane

      @createPane_ tailerPane, paneOptions, file

      if emitChange
        change        =
          context     :
            file      :
              content : content
              path    : file.path
              machine :
                uid   : file.machine.uid

        @emitChange tailerPane, change

      return tailerPane


  createTerminal: (options) ->

    { appManager }   = kd.singletons
    frontApp         = appManager.getFrontApp()
    options.machine ?= frontApp.mountedMachine

    terminalPane = new IDETerminalPane options
    { isActivePane } = options

    terminalPane.ready -> frontApp.setRealtimeManager? terminalPane

    { webtermView } = terminalPane

    webtermView.on 'viewAppended', =>
      webtermView.terminal.on 'ScreenSizeChanged', kd.utils.debounce 100, (size) =>
        @emitChange terminalPane, { context: { size } }, 'TerminalScreenSizeChanged'

    @createPane_ terminalPane, { name: 'Terminal', isActivePane }


  emitChange: (pane = {}, change = { context: {} }, type = 'NewPaneCreated') ->

    change.context.paneType     = pane.options?.paneType or null
    change.context.paneHash     = pane.hash or null
    change.context.ideViewHash  = change.context.ideViewHash or @hash

    change.type   = type
    change.origin = nick()

    if type in [ 'PaneRemoved', 'TabChanged' ] and pane.file
      change.context.file = { path: pane.file.path }

    @emit 'ChangeHappened', change


  createDrawingBoard: (paneHash) ->

    drawingPane = new IDEDrawingPane { hash: paneHash }
    @createPane_ drawingPane, { name: 'Drawing' }

    @emitChange  drawingPane, { context: {} }  unless paneHash


  showView: (view, name = 'Search Result') -> @createPane_ view, { name }


  updateStatusBar: (paneType, data) ->

    appManager = kd.getSingleton 'appManager'

    unless paneType
      subView  = @getActivePaneView()
      paneType = subView.getOptions().paneType  if subView

    unless data
      if paneType is 'editor'
        { file } = subView.getOptions()
        { ace }  = subView.aceView
        cursor   = if ace.editor? then ace.editor.getCursorPosition() else row: 0, column: 0

        file.name = @trimUntitledFileName file.name

        data   = { file, cursor }

      else if paneType is 'terminal'
        machineName = subView.machine.getName()
        data   = { machineName }

      else if paneType is 'drawing'
        data   = 'Use this panel to draw something'

      else if paneType is 'tailer'
        { file } = subView.getOptions()
        data = "Watching changes on #{file.getPath()}"

      else if paneType is 'searchResult'
        { stats, searchText } = subView.getOptions()
        data = { stats, searchText }

    appManager.tell 'IDE', 'updateStatusBar', paneType, data


  removeOpenDocument: -> # legacy, should be reimplemented in ace bundle.


  getActivePaneView: -> return @tabView.getActivePane()?.view


  focusTab: ->

    pane = @getActivePaneView()
    return unless pane

    { panes } = @tabView

    kd.utils.defer ->
      { paneType } = pane.getOptions()
      appManager   = kd.getSingleton 'appManager'

      for _pane in panes when _pane.view isnt pane
        _pane.view.setFocus? no

      pane.setFocus? yes

      if paneType is 'editor'
        appManager.tell 'IDE', 'setFindAndReplaceViewDelegate'
        appManager.tell 'IDE', 'showFindAndReplaceViewIfNecessary'
      else
        appManager.tell 'IDE', 'hideFindAndReplaceView'

    if not @suppressChangeHandlers and not @isReadOnly
      @emitChange pane, { context: {} }, 'TabChanged'


  goToLine: ->
    @ace = @getActivePaneView().aceView.ace
    @ace.showGotoLine()
    @tabView.on 'GotoLineNeedsToBeClosed', =>
      @ace.hideGotoLine()


  click: ->

    appManager = kd.getSingleton 'appManager'

    appManager.tell 'IDE', 'setActiveTabView', @tabView
    appManager.tell 'IDE', 'setFindAndReplaceViewDelegate'

    @updateStatusBar()

    super


  openSavedFile: (file, content) ->

    pane = @tabView.getActivePane()

    if pane.data instanceof FSFile and @isDummyFilePath pane.data.path
      @tabView.removePane pane, shouldDetach = no, quiet = no, askforsave = no

    @openFile file, content


  openFile: (file, content, callback = kd.noop, emitChange, isActivePane) ->

    if @openFiles.indexOf(file) > -1
      editorPane = @switchToEditorTabByFile file
      callback editorPane
    else
      kallback = (pane) =>
        @openFiles.push file  if pane
        callback pane

      @createEditor file, content, kallback, emitChange, isActivePane


  switchToEditorTabByFile: (file) ->

    for pane, index in @tabView.panes when file is pane.getData()
      @tabView.showPaneByIndex index
      return editorPane = pane.view


  toggleFullscreen: (dontToggleSidebar = no) ->

    fullscreen = 'fullscreen'
    { appManager : { frontApp }, windowController, mainView } = kd.singletons

    if @isFullScreen
      kd.utils.wait 300, => # Just wait for the CSS transition.
        @unsetClass fullscreen
        frontApp.getView().toggleClass fullscreen
    else
      @setClass fullscreen
      frontApp.getView().toggleClass fullscreen
      Tracker.track Tracker.IDE_ENTERED_FULLSCREEN

    @isFullScreen     = not @isFullScreen
    dontToggleSidebar = dontToggleSidebar or (@isFullScreen and mainView.isSidebarCollapsed)

    @holderView.setFullscreenHandleState @isFullScreen

    mainView.toggleSidebar()  unless dontToggleSidebar
    windowController.notifyWindowResizeListeners()


  handleCloseFullScreen: -> @toggleFullscreen yes


  handlePaneRemoved: (pane) ->

    file = pane.getData()
    @openFiles.splice @openFiles.indexOf(file), 1
    @emitChange pane.view, { context: {} }, 'PaneRemoved'
    @emit 'PaneRemoved', pane


  getDummyFilePath: (uniquePath = yes) ->

    filePath = 'localfile:/Untitled.txt'
    filePath += "@#{Date.now()}"  if uniquePath

    return filePath


  isDummyFilePath: (filePath) -> filePath.indexOf('localfile:/') is 0


  openMachineTerminal: (machine) -> @createTerminal { machine }


  closeTabByFile: (file)  ->

    for pane in @tabView.panes when pane?.data is file
      pane.getOptions().aceView.ace.contentChanged = no # hook to avoid file close modal
      @tabView.removePane pane


  closeUntitledFileIfNotChanged: ->

    for pane in @tabView.panes when pane

      isFsFile = pane.data instanceof FSFile

      return unless isFsFile

      isLocal    = pane.data.path.indexOf('localfile:/') > -1
      isEmpty    = pane.view.getEditor()?.getSession()?.getValue() is '' # intentional `?` checks
      hasContent = pane.data.initialContents

      @tabView.removePane pane  if isLocal and isEmpty and not hasContent


  getPlusMenuItems: ->

    { appManager } = kd.singletons

    frontApp = appManager.getFrontApp()
    machine  = frontApp.mountedMachine

    sessions = machine?.getBaseKite().terminalSessions or []

    terminalSessions = {}
    activeSessions   = []
    inActiveSessions = []

    # Collect active sessions
    frontApp.forEachSubViewInIDEViews_ 'terminal', (pane) ->
      activeSessions.push pane.remote.session  if pane.remote?

    sessions.forEach (session, i) =>
      isActive = session in activeSessions

      # Collect inactive sessions
      inActiveSessions.push session  unless isActive

      terminalSessions["Session (#{session[0..5]}) &nbsp"] =
        disabled          : isActive
        separator         : sessions.length is i
        children          :
          'Open'          :
            disabled      : isActive
            callback      : =>
              @createTerminal { machine, session }
              Tracker.track Tracker.IDE_OPEN_TERMINAL_SESSION
          'Terminate'     :
            callback      : =>
              @terminateSession machine, session
              Tracker.track Tracker.IDE_TERMINATE_TERMINAL_SESSION

    canTerminateSessions  = sessions.length > 0 and frontApp.amIHost

    terminalSessions['New Session'] =
      callback            : =>
        @createTerminal { machine }
        Tracker.track Tracker.IDE_NEW_TERMINAL_SESSION
      separator           : (canTerminateSessions or inActiveSessions.length)

    if inActiveSessions.length
      terminalSessions['Open All']  =
        callback          : =>
          @openAllSessions { machine, sessions : inActiveSessions }
          Tracker.track Tracker.IDE_OPEN_ALL_TERMINAL_SESSIONS

    if canTerminateSessions
      terminalSessions['Terminate all'] =
        callback          : =>
          @terminateSessions machine
          Tracker.track Tracker.IDE_TERMINATE_ALL_TERMINALS

    items =
      'New File'          : { callback : =>
        newFile = FSHelper.createFileInstance { path: @getDummyFilePath(), machine }
        kd.singletons.appManager.tell 'IDE', 'openFile', { file: newFile }
        Tracker.track Tracker.IDE_NEW_FILE }
      'New Terminal'      : { children : terminalSessions }
      # 'New Browser'       : callback : => @createPreview()
      'New Drawing Board' :
        callback          : =>
          @createDrawingBoard()
          Tracker.track Tracker.IDE_NEW_DRAWING_BOARD
        separator         : yes
      'Split Vertically'  :
        callback          : -> frontApp.splitVertically()
      'Split Horizontally':
        callback          : -> frontApp.splitHorizontally()

    items['']           = # TODO: `type: 'separator'` also creates label, see: https://cloudup.com/c90pFQS_n6X
      type              : 'separator'

    label                 = if @isFullScreen then 'Exit Fullscreen' else 'Enter Fullscreen'
    items[label]          =
      callback            : => @toggleFullscreen()

    return items


  openAllSessions: (params) ->

    { machine, sessions } = params

    for session in sessions
      @createTerminal { machine, session }


  createPlusContextMenu: ->

    return  if @isReadOnly

    offset      = @holderView.plusHandle.$().offset()
    offsetLeft  = offset.left - 133
    margin      = if offsetLeft >= -1 then -20 else 12
    placement   = 'top'
    options     =
      delegate  : this
      x         : Math.max 0, offsetLeft
      y         : offset.top + 30
      arrow     : { placement, margin }

    contextMenu = new KDContextMenu options, @getPlusMenuItems()

    contextMenu.once 'ContextMenuItemReceivedClick', -> contextMenu.destroy()


  closeSplitView: ->

    { frontApp } = kd.singletons.appManager
    frontApp.setActiveTabView @tabView

    frontApp.mergeSplitView()


  terminateSessions: (machine) ->

    machine.getBaseKite().webtermKillSessions()

    .catch (err) ->
      kd.warn 'Failed to terminate sessions', err


  terminateSession: (machine, session) ->

    machine.getBaseKite().webtermKillSession { session }

    .catch (err) ->
      kd.warn "Failed to terminate session, possibly it's already dead.", err


  dragover: (event) -> kd.utils.stopDOMEvent event


  drop: (event) ->

    selector  = '.kdtabhandle:not(.visible-tab-handle)'
    $target   = $(event.originalEvent.target).closest(selector)
    index     = $target?.index()

    index = null  if index < 0

    kd.singletons.appManager.tell 'IDE', 'handleTabDropped', event, @parent, index


  handleWebtermCreated: (paneView) ->

    terminalPane   = paneView.view
    options        = terminalPane.getOptions()
    terminalHandle = @tabView.getHandleByPane paneView

    { machine, joinUser, fitToWindow } = options

    terminalPane.webtermView.on 'click', @bound 'click'

    if fitToWindow
      kd.utils.defer -> terminalPane.webtermView.triggerFitToWindow()

    @emit 'UpdateWorkspaceSnapshot'

    { remote : { session } } = terminalPane

    unless joinUser
      change =
        context   :
          session : session
          machine :
            uid   : machine.uid

      @emitChange terminalPane, change

    ###
    Rename terminal tab to terminal session name only if terminal has already been
    renamed before, i.e. session name isn't auto generated string which lenght is 24 symbols.
    If session name is auto generated string, leave terminal tab name with its default value 'Terminal'
    ###
    unless session.length is DEFAULT_SESSION_NAME_LENGTH
      terminalHandle.setTitle session

  handleTerminalRenamingRequested: (tabHandle, newTitle) ->

    paneView     = tabHandle.getOptions().pane
    terminalPane = paneView.view
    options      = terminalPane.getOptions()

    { machine } = options
    { remote : { session } } = terminalPane

    kite    = machine.getBaseKite()
    request =
      newName : newTitle
      oldName : session

    kite.init()
    .then ->
      kite.webtermRename request

    .then =>
      @renameTerminal paneView, machine, newTitle

      @emit 'UpdateWorkspaceSnapshot'

      change =
        context   :
          session : newTitle
          machine :
            uid   : machine.uid

      @emitChange terminalPane, change, 'TerminalRenamed'

    .catch (err) ->
      showError err

  renameTerminal: (paneView, machine, newTitle) ->

    terminalPane = paneView.view
    terminalHandle = @tabView.getHandleByPane paneView

    terminalPane.setSession newTitle
    terminalHandle.setTitle newTitle

    machine.getBaseKite().fetchTerminalSessions()


  toggleVisibility = (handle, state) ->

    if   handle.getElement() then el.classList.add 'in'
    else el.classList.remove 'in'


  setupSplitHandleNotifier = (handle) ->

    splitTop = handle.getY()
    splitLeft = handle.getX()

    notifier = new ProximityNotifier
      handler: (event) ->
        { pageX, pageY } = event

        distX = Math.pow splitLeft - pageX, 2
        distY = Math.pow splitTop - pageY, 2
        dist  = Math.sqrt distX + distY

        return dist < HANDLE_PROXIMITY_DISTANCE

    notifier.on 'MouseInside', -> toggleVisibility handle, yes
    notifier.on 'MouseOutside', -> toggleVisibility handle

    handle.on 'KDObjectWillBeDestroyed', notifier.bound 'destroy'

    return notifier


  setHash: (hash) -> @hash = hash or generatePassword 64, no


  handleTabMoved: (params) ->

    { view, tabView, targetTabView } = params

    if view instanceof IDEEditorPane
      view.updateAceViewDelegate targetTabView.parent

    change =
      context:
        originIDEViewHash : tabView.parent.hash
        targetIDEViewHash : targetTabView.parent.hash

    @emitChange view, change, 'IDETabMoved'


  handleSplitViewCreated: (params) ->

    { mainView, appManager }            = kd.singletons
    { ideView, newIdeView, direction }  = params

    change =
      context:
        ideViewHash     : ideView.hash
        newIdeViewHash  : newIdeView.hash
        direction       : direction

    @emitChange newIdeView, change, 'NewSplitViewCreated'

    if ideView.isFullScreen
      ideView.toggleFullscreen()
      appManager.tell 'IDE', 'collapseSidebar'
      mainView.toggleSidebar()


  handleSplitViewMerged: (params) ->

    { ideViewHash, targetIdeView } = params

    change =
      context:
        ideViewHash : ideViewHash

    @emitChange targetIdeView, change, 'SplitViewMerged'
