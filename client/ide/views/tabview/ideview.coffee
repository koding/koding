class IDE.IDEView extends IDE.WorkspaceTabView

  constructor: (options = {}, data) ->

    options.tabViewClass = AceApplicationTabView

    super options, data

    @openFiles = []
    @bindListeners()

  bindListeners: ->
    @on 'PlusHandleClicked', @bound 'createPlusContextMenu'

    @tabView.on 'VMTerminalRequested',    @bound 'openVMTerminal'
    @tabView.on 'VMWebPageRequested',     @bound 'openVMWebPage'
    @tabView.on 'ShortcutsViewRequested', @bound 'createShortcutsView'
    @tabView.on 'TerminalPaneRequested',  @bound 'createTerminal'
    @tabView.on 'PreviewPaneRequested',   @bound 'createPreview'
    @tabView.on 'DrawingPaneRequested',   @bound 'createDrawingBoard'

    @tabView.on 'FileNeedsToBeOpened', (file, contents) =>
      @closeUntitledFileIfNotChanged()
      @openFile file, contents

    @tabView.on 'PaneDidShow', =>
      @updateStatusBar()
      @focusTab()

    @once 'viewAppended', => KD.utils.wait 300, =>
      @createEditor()
      @showShortcutsOnce()

  getPlusMenuItems: ->
    return {
      'Editor'        : callback : => @createEditor()
      'Terminal'      : callback : => @createTerminal()
      'Browser'       : callback : => @createPreview()
      'Drawing Board' : callback : => @createDrawingBoard()
    }

  createPane_: (view, paneOptions, paneData) ->
    unless view or paneOptions
      return new Error 'Missing argument for createPane_ helper'

    unless view instanceof KDView
      return new Error 'View must be an instance of KDView'

    pane = new KDTabPaneView paneOptions, paneData
    pane.addSubView view
    @tabView.addPane pane

    pane.once 'KDObjectWillBeDestroyed', => @handlePaneRemoved pane

  createEditor: (file, content) ->
    file        = file    or FSHelper.createFileFromPath @getDummyFilePath()
    content     = content or ''
    editorPane  = new IDE.EditorPane { file, content, delegate: this }
    paneOptions =
      name      : file.name
      editor    : editorPane
      aceView   : editorPane.aceView # this is required for ace app. see AceApplicationTabView:6

    editorPane.once 'EditorIsReady', ->
      editorPane.aceView.ace.on 'ace.change.cursor', (cursor) ->
        appManager = KD.getSingleton 'appManager'
        appManager.tell 'IDE', 'updateStatusBar', 'editor', { file, cursor }

    @createPane_ editorPane, paneOptions, file

  createShortcutsView: ->
    @createPane_ new IDE.ShortcutsView, { name: 'Shortcuts' }

  createTerminal: (vm) ->
    terminalPane = new IDE.TerminalPane { vm }
    @createPane_ terminalPane, { name: 'Terminal' }

  createDrawingBoard: ->
    @createPane_ new IDE.DrawingPane, { name: 'Drawing' }

  createPreview: (url) ->
    previewPane = new IDE.PreviewPane { url }
    @createPane_ previewPane, { name: 'Browser' }

    previewPane.on 'LocationChanged', (newLocation) =>
      @updateStatusBar 'preview', newLocation

  updateStatusBar: (paneType, data) ->
    appManager = KD.getSingleton 'appManager'

    unless paneType
      subView  = @tabView.getActivePane().getSubViews().first
      paneType = subView.getOptions().paneType

    unless data
      if paneType is 'editor'
        {file} = subView.getOptions()
        {ace}  = subView.aceView
        cursor = if ace.editor? then ace.editor.getCursorPosition() else row: 0, column: 0
        data   = { file, cursor }

      else if paneType is 'terminal'
        vmc    = KD.getSingleton 'vmController'
        vmName = subView.getOptions().vm?.hostnameAlias or vmc.defaultVmName
        data   = vmName: vmName.split('.').first

      else if paneType is 'preview'
        data   = subView.getOptions().url or 'Enter a URL to browse...'

      else if paneType is 'drawing'
        data   = 'Use this panel to draw something'

    appManager.tell 'IDE', 'updateStatusBar', paneType, data

  removeOpenDocument: ->
    # TODO: This method is legacy, should be reimplemented in ace bundle.

  focusTab: ->
    pane     = @tabView.getActivePane().getSubViews().first
    paneType = pane.getOptions().paneType

    KD.utils.defer ->
      if      paneType is 'editor'   then pane.aceView.ace.focus()
      else if paneType is 'terminal' then pane.webtermView?.setFocus yes

  click: ->
    super
    KD.getSingleton('appManager').tell 'IDE', 'setActiveTabView', @tabView

  openFile: (file, content) ->
    if @openFiles.indexOf(file) > -1
      @switchToEditorTabByFile file
    else
      @createEditor file, content
      @openFiles.push file

  switchToEditorTabByFile: (file) ->
    for pane, index in @tabView.panes when file is pane.getData()
      @tabView.showPaneByIndex index

  handlePaneRemoved: (pane) ->
    file = pane.getData()
    @openFiles.splice @openFiles.indexOf(file), 1
    @emit 'PaneRemoved'

  getDummyFilePath: ->
    return 'localfile://Untitled.txt'

  openVMTerminal: (vm) ->
    @createTerminal vm

  openVMWebPage: (vm) ->
    @createPreview vm.hostnameAlias

  closeUntitledFileIfNotChanged: ->
    for pane in @tabView.panes
      if pane.data instanceof FSFile and pane.data.path is @getDummyFilePath()
        if pane.subViews.first.getValue() is ''
          @tabView.removePane pane

  showShortcutsOnce: ->
    @appStorage = KD.getSingleton('appStorageController').storage 'IDE', '1.0.0'
    @appStorage.fetchStorage (storage) =>
      isShortcutsShown = @appStorage.getValue 'isShortcutsShown'
      unless isShortcutsShown
        @createShortcutsView()
        @appStorage.setValue 'isShortcutsShown', yes

  createPlusContextMenu: ->
    offset        = @holderView.plusHandle.$().offset()
    contextMenu   = new KDContextMenu
      delegate    : this
      x           : offset.left - 133
      y           : offset.top  + 30
      arrow       :
        placement : 'top'
        margin    : -20
    , @getPlusMenuItems()

    contextMenu.once 'ContextMenuItemReceivedClick', ->
      contextMenu.destroy()
