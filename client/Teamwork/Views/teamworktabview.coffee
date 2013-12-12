class TeamworkTabView extends CollaborativePane

  constructor: (options = {}, data) ->

    super options, data

    @createElements()
    @keysRef  = @workspaceRef.child "keys"
    @indexRef = @workspaceRef.child "index"

    @recoverSession()  if @isJoinedASession
    @tabView.on "PaneDidShow", (pane) =>
      @indexRef.set pane.getOptions().indexKey

  createElements: ->
    @tabHandleHolder = new ApplicationTabHandleHolder
      delegate       : this

    @tabView = new ApplicationTabView
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
    }

  recoverSession: ->
    @keysRef.once "value" , (snapshot) =>
      data = snapshot.val()
      return unless data

      for key, value of data
        switch value.type
          when "dashboard" then @createDashboard()
          when "editor"
            file = FSHelper.createFileFromPath value.filePath
            @createEditor file, "", value.sessionKey
          when "terminal" then @createTerminal value.sessionKey
          when "preview"  then @createPreview  value.sessionKey

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
