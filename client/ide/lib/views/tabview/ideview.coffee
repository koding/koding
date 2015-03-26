kd = require 'kd'
KDContextMenu = kd.ContextMenu
KDCustomHTMLView = kd.CustomHTMLView
KDSplitViewPanel = kd.SplitViewPanel
KDTabPaneView = kd.TabPaneView
KDView = kd.View
nick = require 'app/util/nick'
FSHelper = require 'app/util/fs/fshelper'
FSFile = require 'app/util/fs/fsfile'
showErrorNotification = require 'app/util/showErrorNotification'
IDEDrawingPane = require '../../workspace/panes/idedrawingpane'
IDEEditorPane = require '../../workspace/panes/ideeditorpane'
IDEPreviewPane = require '../../workspace/panes/idepreviewpane'
IDEShortcutsView = require '../shortcutsview/ideshortcutsview'
IDETerminalPane = require '../../workspace/panes/ideterminalpane'
IDEWorkspaceTabView = require '../../workspace/ideworkspacetabview'
IDEApplicationTabView = require './ideapplicationtabview.coffee'
IDEHelpers = require '../../idehelpers'


module.exports = class IDEView extends IDEWorkspaceTabView

  constructor: (options = {}, data) ->

    options.tabViewClass     = IDEApplicationTabView
    options.createNewEditor ?= yes

    super options, data

    @openFiles = []
    @bindListeners()


  bindListeners: ->

    @on 'PlusHandleClicked', @bound 'createPlusContextMenu'

    @tabView.on 'MachineTerminalRequested', @bound 'openMachineTerminal'
    @tabView.on 'MachineWebPageRequested',  @bound 'openMachineWebPage'
    @tabView.on 'ShortcutsViewRequested',   @bound 'createShortcutsView'
    @tabView.on 'TerminalPaneRequested',    @bound 'createTerminal'
    # obsolete: 'preview file' feature was removed (bug #82710798)
    @tabView.on 'PreviewPaneRequested',     (url) -> global.open "http://#{url}"
    @tabView.on 'DrawingPaneRequested',     @bound 'createDrawingBoard'
    @tabView.on 'ViewNeedsToBeShown',       @bound 'showView'
    @tabView.on 'TabNeedsToBeClosed',       @bound 'closeTabByFile'
    @tabView.on 'GoToLineRequested',        @bound 'goToLine'

    @tabView.on 'FileNeedsToBeOpened', (file, contents, callback, emitChange) =>
      @closeUntitledFileIfNotChanged()
      @openFile file, contents, callback, emitChange

    @tabView.on 'PaneDidShow', =>
      @updateStatusBar()
      @focusTab()

    @tabView.on 'PaneAdded', (pane) =>
      return unless pane.options.editor
      {tabHandle} = pane

      icon = new KDCustomHTMLView
        tagName  : 'span'
        cssClass : 'options'
        click    : => @createEditorMenu tabHandle, icon

      tabHandle.addSubView icon, null, yes

    # This is a custom event for IDEApplicationTabView
    # to distinguish between user actions and programmed actions
    @tabView.on 'PaneRemovedByUserAction', (pane)=>
      {view} = pane
      if view instanceof IDETerminalPane
        sessionId = view.session or view.webtermView.sessionId
        @terminateSession @mountedMachine, sessionId


  createPane_: (view, paneOptions, paneData) ->

    unless view or paneOptions
      return new Error 'Missing argument for createPane_ helper'

    unless view instanceof KDView
      return new Error 'View must be an instance of KDView'

    if view instanceof IDEEditorPane
      paneOptions.name = @trimUntitledFileName paneOptions.name

    pane = new KDTabPaneView paneOptions, paneData
    pane.addSubView view
    pane.view = view
    @tabView.addPane pane

    pane.once 'KDObjectWillBeDestroyed', => @handlePaneRemoved pane

    return pane


  trimUntitledFileName: (name) ->

    untitledNameRegex = /Untitled[0-9\-]*.txt/
    matchedPattern    = untitledNameRegex.exec name

    return  if matchedPattern then matchedPattern.first else name


  createEditor: (file, content, callback = kd.noop, emitChange = yes) ->

    unless file # create dummy file and pass machine to that file
      path    = @getDummyFilePath()
      machine = kd.singletons.appManager.getFrontApp().mountedMachine
      file    = FSHelper.createFileInstance { path, machine }

    # we need to show a notification that file is read-only or not accessible
    # only if it is opened by user action
    # we use emitChange to detect this case for now
    notifyIfNoPermissions = emitChange

    if file.isDummyFile() or not notifyIfNoPermissions
      return @createEditorAfterFileCheck file, content, callback, emitChange, no

    file.fetchPermissions (err, result) =>

      return showErrorNotification err  if err

      { readable, writable } = result
      if not readable
        IDEHelpers.showFileAccessDeniedError()
        return callback()

      @createEditorAfterFileCheck file, content, callback, emitChange, not writable


  createEditorAfterFileCheck: (file, content, callback, emitChange, isReadOnly) ->

    content     = content or ''
    editorPane  = new IDEEditorPane { file, content, delegate: this }

    paneOptions =
      name      : file.name
      editor    : editorPane
      aceView   : editorPane.aceView

    editorPane.once 'EditorIsReady', =>
      ace        = editorPane.getAce()
      appManager = kd.getSingleton 'appManager'

      if file.isDummyFile()
        ace.on 'FileContentChanged', => @emit 'UpdateWorkspaceSnapshot'

      ace.on 'ace.change.cursor', (cursor) ->
        appManager.tell 'IDE', 'updateStatusBar', 'editor', { file, cursor }

      ace.on 'FindAndReplaceViewRequested', (withReplaceMode) ->
        appManager.tell 'IDE', 'showFindReplaceView', withReplaceMode

      ace.editor.scrollToRow 0
      editorPane.goToLine 1

      if isReadOnly
        editorPane.makeReadOnly()
        IDEHelpers.showFileReadOnlyNotification()

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

    return editorPane


  createShortcutsView: ->

    @createPane_ new IDEShortcutsView, { name: 'Shortcuts' }

  createTerminal: (options) ->

    { appManager }   = kd.singletons
    frontApp         = appManager.getFrontApp()
    options.machine ?= frontApp.mountedMachine

    unless options.path
      workspaceData = frontApp.workspaceData or {}
      { rootPath, isDefault } = workspaceData

      if rootPath and not isDefault
        options.path = frontApp.workspaceData.rootPath

    { machine, joinUser, fitToWindow } = options

    terminalPane = new IDETerminalPane options
    @createPane_ terminalPane, { name: 'Terminal' }

    terminalPane.once 'WebtermCreated', =>
      terminalPane.webtermView.on 'click', @bound 'click'

      if fitToWindow
        kd.utils.defer -> terminalPane.webtermView.triggerFitToWindow()

      @emit 'UpdateWorkspaceSnapshot'

      unless joinUser
        change        =
          context     :
            session   : terminalPane.remote.session
            machine   :
              uid     : machine.uid

        @emitChange terminalPane, change


  emitChange: (pane = {}, change = { context: {} }, type = 'NewPaneCreated') ->

    change.context.paneType = pane.options?.paneType or null
    change.context.paneHash = pane.hash or null

    change.type   = type
    change.origin = nick()

    if type in [ 'PaneRemoved', 'TabChanged' ] and pane.file
      change.context.file = path: pane.file.path

    @emit 'ChangeHappened', change


  createDrawingBoard: (paneHash) ->

    drawingPane = new IDEDrawingPane { hash: paneHash }
    @createPane_ drawingPane, { name: 'Drawing' }

    unless paneHash
      @emitChange  drawingPane, context: {}


  createPreview: (url) ->

    previewPane = new IDEPreviewPane { url }
    @createPane_ previewPane, { name: 'Browser' }

    previewPane.on 'LocationChanged', (newLocation) =>
      @updateStatusBar 'preview', newLocation

    @emitChange previewPane, context: { url }


  showView: (view) ->

    @createPane_ view, { name: 'Search Result' }


  updateStatusBar: (paneType, data) ->

    appManager = kd.getSingleton 'appManager'

    unless paneType
      subView  = @getActivePaneView()
      paneType = subView.getOptions().paneType  if subView

    unless data
      if paneType is 'editor'
        {file} = subView.getOptions()
        {ace}  = subView.aceView
        cursor = if ace.editor? then ace.editor.getCursorPosition() else row: 0, column: 0

        file.name = @trimUntitledFileName file.name

        data   = { file, cursor }

      else if paneType is 'terminal'
        machineName = subView.machine.getName()
        data   = { machineName }

      else if paneType is 'preview'
        data   = subView.getOptions().url or 'Enter a URL to browse...'

      else if paneType is 'drawing'
        data   = 'Use this panel to draw something'

      else if paneType is 'searchResult'
        {stats, searchText} = subView.getOptions()
        data = { stats, searchText }

    appManager.tell 'IDE', 'updateStatusBar', paneType, data


  removeOpenDocument: -> # legacy, should be reimplemented in ace bundle.


  getActivePaneView: -> return @tabView.getActivePane()?.view


  focusTab: ->

    pane = @getActivePaneView()
    return unless pane

    kd.utils.defer =>
      {paneType} = pane.getOptions()
      appManager = kd.getSingleton 'appManager'

      pane.setFocus? yes

      if paneType is 'editor'
        appManager.tell 'IDE', 'setFindAndReplaceViewDelegate'
        appManager.tell 'IDE', 'showFindAndReplaceViewIfNecessary'
      else
        appManager.tell 'IDE', 'hideFindAndReplaceView'

    if not @suppressChangeHandlers and not @isReadOnly
      @emitChange pane, context: {}, 'TabChanged'


  goToLine: ->

    @getActivePaneView().aceView.ace.showGotoLine()


  click: ->

    super

    appManager = kd.getSingleton 'appManager'

    appManager.tell 'IDE', 'setActiveTabView', @tabView
    appManager.tell 'IDE', 'setFindAndReplaceViewDelegate'

    @updateStatusBar()


  openSavedFile: (file, content) ->

      pane = @tabView.getActivePane()
      if pane.data instanceof FSFile and @isDummyFilePath pane.data.path
        @tabView.removePane @tabView.getActivePane()
      @openFile file, content



  openFile: (file, content, callback = kd.noop, emitChange) ->

    if @openFiles.indexOf(file) > -1
      editorPane = @switchToEditorTabByFile file
      callback editorPane
    else
      kallback = (pane) =>
        @openFiles.push file  if pane
        callback pane

      @createEditor file, content, kallback, emitChange


  switchToEditorTabByFile: (file) ->

    for pane, index in @tabView.panes when file is pane.getData()
      @tabView.showPaneByIndex index
      return editorPane = pane.view


  toggleFullscreen: ->

    @toggleClass 'fullscren'
    kd.getSingleton('windowController').notifyWindowResizeListeners()
    @isFullScreen = !@isFullScreen


  handlePaneRemoved: (pane) ->

    file = pane.getData()
    @openFiles.splice @openFiles.indexOf(file), 1
    @emitChange pane.view, context: {}, 'PaneRemoved'
    @emit 'PaneRemoved', pane


  getDummyFilePath: (uniquePath = yes) ->

    filePath = "localfile:/Untitled.txt"
    filePath += "@#{Date.now()}"  if uniquePath

    return filePath


  isDummyFilePath: (filePath) -> filePath.indexOf(@getDummyFilePath no) is 0


  openMachineTerminal: (machine) -> @createTerminal { machine }


  openMachineWebPage: (machine) -> @createPreview machine.ipAddress


  closeTabByFile: (file)  ->

    for pane in @tabView.panes when pane?.data is file
      pane.getOptions().aceView.ace.contentChanged = no # hook to avoid file close modal
      @tabView.removePane pane


  closeUntitledFileIfNotChanged: ->

    for pane in @tabView.panes when pane

      isFsFile = pane.data instanceof FSFile

      return unless isFsFile

      isLocal  = pane.data.path.indexOf('localfile:/') > -1
      isEmpty  = pane.view.getEditor()?.getSession()?.getValue() is '' # intentional `?` checks

      @tabView.removePane pane  if isLocal and isEmpty


  getPlusMenuItems: ->

    {appManager} = kd.singletons

    frontApp = appManager.getFrontApp()
    machine  = frontApp.mountedMachine

    sessions = machine?.getBaseKite().terminalSessions or []

    terminalSessions = {}
    activeSessions   = []

    frontApp.forEachSubViewInIDEViews_ 'terminal', (pane) =>
      activeSessions.push pane.remote.session  if pane.remote?

    sessions.forEach (session, i) =>
      isActive = session in activeSessions
      terminalSessions["Session (#{session[0..5]}) &nbsp"] =
        disabled          : isActive
        separator         : sessions.length is i
        children          :
          'Open'          :
            disabled      : isActive
            callback      : => @createTerminal { machine, session }
          'Terminate'     :
            callback      : => @terminateSession machine, session

    canTerminateSessions  = sessions.length > 0 and frontApp.amIHost

    terminalSessions["New Session"] =
      callback            : => @createTerminal { machine }
      separator           : canTerminateSessions

    if canTerminateSessions
      terminalSessions["Terminate all"] =
        callback          : => @terminateSessions machine

    items =
      'New File'          : callback : =>
         newFile = FSHelper.createFileInstance { path: @getDummyFilePath(), machine }
         kd.singletons.appManager.tell 'IDE', 'openFile', newFile
      'New Terminal'      : children : terminalSessions
      # 'New Browser'       : callback : => @createPreview()
      'New Drawing Board' :
        callback          : => @createDrawingBoard()
        separator         : yes
      'Split Vertically'  :
        callback          : -> frontApp.splitVertically()
      'Split Horizontally':
        callback          : -> frontApp.splitHorizontally()

    if @parent instanceof KDSplitViewPanel
      items['Undo Split'] =
        separator         : yes
        callback          : -> frontApp.mergeSplitView()
    else
      items['']           = # TODO: `type: 'separator'` also creates label, see: https://cloudup.com/c90pFQS_n6X
        type              : 'separator'

    label                 = if @isFullScreen then 'Exit Fullscreen' else 'Enter Fullscreen'
    items[label]          =
      callback            : @bound 'toggleFullscreen'

    return items


  createEditorMenu: (tabHandle, icon) ->

    tabHandle.setClass 'menu-visible'
    kd.getSingleton('appManager').tell 'IDE', 'showStatusBarMenu', this, icon

    kd.utils.defer =>
      @menu.once 'KDObjectWillBeDestroyed', =>
        tabHandle.unsetClass 'menu-visible'
        delete @menu


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


  terminateSessions: (machine)->

    machine.getBaseKite().webtermKillSessions()

    .catch (err)->
      kd.warn "Failed to terminate sessions", err


  terminateSession: (machine, session) ->

    machine.getBaseKite().webtermKillSession {session}

    .catch (err)->
      kd.warn "Failed to terminate session, possibly it's already dead.", err
