class TeamworkTabView extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @createElements()
    @keysRef  = @workspaceRef.child "keys"
    @indexRef = @workspaceRef.child "index"

    @tabView.on "PaneDidShow", (pane) =>
      @indexRef.set pane.getOptions().indexKey

    @indexRef.on "value", (snapshot) =>
      key = snapshot.val()
      return unless key

      for pane in @tabView.panes
        if pane.getOptions().indexKey is key
          @tabView.showPaneByIndex @tabView.getPaneIndex pane

    @keysRef.on "child_added", (snapshot) =>
      data    = snapshot.val()
      key     = data.indexKey
      {panes} = @tabView
      isExist = yes for pane in panes when pane.getOptions().indexKey is key

      @createTabFromFirebaseData data  unless isExist

    @keysRef.on "child_removed", (snapshot) =>
      data = snapshot.val()
      return unless data

      {indexKey} = data
      for pane in @tabView.panes
        if pane.getOptions().indexKey is indexKey
          @tabView.removePane pane

  createElements: ->
    @tabHandleHolder = new ApplicationTabHandleHolder delegate: this
    @tabView         = new ApplicationTabView
      delegate                  : this
      lastTabHandleMargin       : 200
      tabHandleContainer        : @tabHandleHolder
      closeAppWhenAllTabsClosed : no

  addNewTab: ->
    @createPlusHandleDropDown()

  createPlusHandleDropDown: ->
    offset        = @tabHandleHolder.plusHandle.$().offset()
    contextMenu   = new JContextMenu
      delegate    : this
      x           : offset.left - 125
      y           : offset.top  + 30
      arrow       :
        placement : "top"
        margin    : -20
    , @getDropdownItems()

    contextMenu.once "ContextMenuItemReceivedClick", ->
      contextMenu.destroy()

  getDropdownItems: ->
    return {
      "Dashboard" :
        separator : yes
        callback  : => @createDashboard()
      "Editor"    :
        callback  : => @createEditor()
      "Terminal"  :
        callback  : => @createTerminal()
      "Preview"   :
        callback  : => @createPreview()
      "Chat"      :
        callback  : => @createChat()
      "Drawing Board":
        callback  : => @createDrawingBoard()
    }


  createDashboard: ->
    return @tabView.showPane @dashboard  if @dashboard

    @dashboard = new KDTabPaneView title: "Dashboard"
    dashboard  = new TeamworkDashboard
      delegate : @workspace.getDelegate()

    @appendPane_ @dashboard, dashboard

    @dashboard.once "KDObjectWillBeDestroyed", =>
      @dashboard = null

    @keysRef.push type: "dashboard"  if @amIHost

  openFile: (file, content) ->
    @createEditor file, content
  createDrawingBoard: (sessionKey, indexKey) ->
    indexKey  = indexKey or @createSessionKey()
    pane      = new KDTabPaneView { title: "Drawing Board", indexKey }
    delegate  = @panel
    drawing   = new CollaborativeDrawingPane { delegate, sessionKey }

    @appendPane_ pane, drawing

    if @amIHost
      @keysRef.push
        type       : "drawing"
        sessionKey : drawing.sessionKey
        indexKey   : indexKey


  createEditor: (file, content = "", sessionKey) ->
    isLocal  = not file
    file     = file or FSHelper.createFileFromPath "localfile:/untitled.txt"
    pane     = new KDTabPaneView title: file.name
    delegate = @getDelegate()
    editor   = new CollaborativeEditorPane { delegate, sessionKey, file, content }

    @appendPane_ pane, editor
    if @amIHost
      @keysRef.push
        type      : "editor"
        sessionKey: editor.sessionKey
        filePath  : file.path

    @workspace.addToHistory "$0 opened a new editor"  if isLocal

  createTerminal: (sessionKey) ->
    pane         = new KDTabPaneView title: "Terminal"
    klass        = if @isJoinedASession then SharableClientTerminalPane else SharableTerminalPane
    delegate     = @getDelegate()
    terminal     = new klass { delegate, sessionKey }

    @appendPane_ pane, terminal

    if @amIHost
      terminal.on "WebtermCreated", =>
        @keysRef.push
          type       : "terminal"
          sessionKey :
            key      : terminal.remote.session
            host     : KD.nick()
            vmName   : KD.getSingleton("vmController").defaultVmName

    @workspace.addToHistory "$0 opened a new terminal"

  createPreview: (sessionKey) ->
    pane     = new KDTabPaneView title: "Browser"
    delegate = @getDelegate()
    preview  = new CollaborativePreviewPane { delegate, sessionKey }

    @appendPane_ pane, preview

    if @amIHost
      @keysRef.push
        type      : "preview"
        sessionKey: preview.sessionKey

    @workspace.addToHistory "$0 opened a new browser"

  createChat: ->
    pane = new KDTabPaneView title: "Chat"
    chat = new ChatPane
      cssClass    : "full-screen"
      delegate    : @workspace

    @appendPane_ pane, chat

  appendPane_: (pane, childView) ->
    pane.addSubView childView
    @tabView.addPane pane

  viewAppended: ->
    super
    @createDashboard()  if @amIHost

  pistachio: ->
    """
      {{> @tabHandleHolder}}
      {{> @tabView}}
    """
