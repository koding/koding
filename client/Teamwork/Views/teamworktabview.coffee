class TeamworkTabView extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @createElements()
    @keysRef    = @workspaceRef.child "keys"
    @indexRef   = @workspaceRef.child "index"
    @requestRef = @workspaceRef.child "request"

    @listenChildRemovedOnKeysRef()
    @listenRequestRef()

    if @amIHost
      @bindRemoteEvents()
    else
      @keysRef.once "value", (snapshot) =>
        data = snapshot.val()
        return unless data

        @keysRefChildAddedCallback value  for key, value of data
        @bindRemoteEvents()

  listenRequestRef: ->
    @requestRef.on "value", (snapshot) =>
      if @amIHost
        request = snapshot.val()
        return unless request

        @createTabFromFirebaseData request
        @requestRef.remove()

  listenPaneDidShow: ->
    @tabView.on "PaneDidShow", (pane) =>
      @indexRef.set pane.getOptions().indexKey

  listenChildRemovedOnKeysRef: ->
    @keysRef.on "child_removed", (snapshot) =>
      data = snapshot.val()
      return unless data

      {indexKey} = data
      for pane in @tabView.panes
        if pane.getOptions().indexKey is indexKey
          @tabView.removePane pane

  bindRemoteEvents: ->
    @listenPaneDidShow()
    @listenIndexRef()
    @listenChildAddedOnKeysRef()

  listenChildAddedOnKeysRef: ->
    @keysRef.on "child_added", (snapshot) =>
      @keysRefChildAddedCallback snapshot.val()

  keysRefChildAddedCallback: (data) ->
    key     = data.indexKey
    {panes} = @tabView
    isExist = yes for pane in panes when pane.getOptions().indexKey is key

    @createTabFromFirebaseData data  unless isExist

  listenIndexRef: ->
    @indexRef.on "value", (snapshot) =>
      key = snapshot.val()
      return unless key

      for pane in @tabView.panes
        if pane.getOptions().indexKey is key
          @tabView.showPaneByIndex @tabView.getPaneIndex pane

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
      "Browser"   :
        callback  : => @createPreview()
      "Drawing Board":
        callback  : => @createDrawingBoard()
      # "Chat"      :
      #   callback  : => @createChat()
    }

  createTabFromFirebaseData: (data) ->
    {sessionKey, indexKey} = data
    switch data.type
      when "dashboard" then @createDashboard()
      when "terminal"  then @createTerminal     sessionKey, indexKey
      when "preview"   then @createPreview      sessionKey, indexKey
      when "drawing"   then @createDrawingBoard sessionKey, indexKey
      when "editor"
        file = FSHelper.createFileFromPath data.filePath
        @createEditor file, "", sessionKey, indexKey

  createDashboard: ->
    return @tabView.showPane @dashboard  if @dashboard

    @dashboard = new KDTabPaneView
      title    : "Dashboard"
      indexKey : "dashboard"

    dashboard  = new TeamworkDashboard
      delegate : @workspace.getDelegate()

    @appendPane_ @dashboard, dashboard

    @dashboard.once "KDObjectWillBeDestroyed", =>
      @dashboard = null

    if @amIHost
      @keysRef.push
        type     : "dashboard"
        indexKey : "dashboard"

    @registerPaneRemoveListener_ @dashboard

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

    @registerPaneRemoveListener_ pane

  registerPaneRemoveListener_: (pane) ->
    pane.on "KDObjectWillBeDestroyed", =>
      paneIndexKey = pane.getOptions().indexKey

      @keysRef.once "value", (snapshot) =>
        data = snapshot.val()
        return unless data

        for key, value of data
          if value.indexKey is paneIndexKey
            @keysRef.child(key).remove()

  createEditor: (file, content = "", sessionKey, indexKey) ->
    isLocal  = not file
    file     = file or FSHelper.createFileFromPath "localfile:/untitled.txt"
    indexKey = indexKey or @createSessionKey()
    pane     = new KDTabPaneView { title: file.name, indexKey }
    delegate = @getDelegate()
    editor   = new CollaborativeEditorPane { delegate, sessionKey, file, content }

    @appendPane_ pane, editor
    if @amIHost
      @keysRef.push
        type      : "editor"
        sessionKey: editor.sessionKey
        filePath  : file.path
        indexKey  : indexKey

    @workspace.addToHistory "$0 opened a new editor"  if isLocal
    @registerPaneRemoveListener_ pane

  openFile: (file, content) ->
    @createEditor file, content

  createTerminal: (sessionKey, indexKey) ->
    indexKey = indexKey or @createSessionKey()
    pane     = new KDTabPaneView { title: "Terminal", indexKey }
    klass    = if @isJoinedASession then SharableClientTerminalPane else SharableTerminalPane
    delegate = @getDelegate()
    terminal = new klass { delegate, sessionKey }

    @appendPane_ pane, terminal

    if @amIHost
      terminal.on "WebtermCreated", =>
        @keysRef.push
          type       : "terminal"
          indexKey   : indexKey
          sessionKey :
            key      : terminal.remote.session
            host     : KD.nick()
            vmName   : KD.getSingleton("vmController").defaultVmName

    @workspace.addToHistory "$0 opened a new terminal"
    @registerPaneRemoveListener_ pane

  createPreview: (sessionKey, indexKey) ->
    indexKey = indexKey or @createSessionKey()
    pane     = new KDTabPaneView { title: "Browser", indexKey }
    delegate = @getDelegate()
    preview  = new CollaborativePreviewPane { delegate, sessionKey }

    @appendPane_ pane, preview

    if @amIHost
      @keysRef.push
        type      : "preview"
        sessionKey: preview.sessionKey
        indexKey  : indexKey

    @workspace.addToHistory "$0 opened a new browser"
    @registerPaneRemoveListener_ pane

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
