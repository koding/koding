class WorkspaceFloatingPaneLauncher extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    # options.cssClass = "workspace-launcher"
    # options.partial  = "<span>+</span>"
    options.cssClass     = "workspace-launcher vertical"

    super options, data

    @sessionKeys         = {}
    @panel               = @getDelegate()
    @workspace           = @panel.getDelegate()
    @container           = new KDView cssClass: "workspace-floating-panes"
    {workspaceRef}       = @workspace
    @isJoinedASession    = @workspace.isJoinedASession()
    @lastActivePaneKey   = null
    @keysRef             = workspaceRef.child "floatingPaneKeys"
    @paneStateRef        = workspaceRef.child "floatingPaneState"
    @paneVisibilityState = chat: no, preview: no, terminal: no

    @panel.addSubView @container

    if @isJoinedASession
      @keysRef.once "value", (snapshot) =>
        @sessionKeys = @workspace.reviveSnapsot snapshot
        @createPanes()
    else
      @createPanes()

    @paneStateRef.on "value", (snapshot) =>
      state  = @workspace.reviveSnapsot snapshot
      return unless state

      for own key, value of state
        pane = @getPaneByType key
        if value is no then @hidePane pane, key else @showPane pane, key

      @resizePanes state

  click: ->
    @toggleClass "active"

  createPanes: ->
    panes = @panel.getOptions().floatingPanes
    panes.forEach (pane) =>
      @createFloatingPane pane
      @addSubView new KDCustomHTMLView
        cssClass : KD.utils.curry "launcher-item", pane
        tooltip  :
          title  : pane.capitalize()
        click    : =>
          @handleLaunch pane

      @panesCreated = yes

  createFloatingPane: (paneKey) ->
    @["create#{paneKey.capitalize()}Pane"]()

  handleLaunch: (paneKey) ->
    pane = @getPaneByType paneKey
    if @lastActivePaneKey is paneKey
      @lastActivePaneKey = null
      @updatePaneVisiblityState paneKey, no
    else
      @lastActivePaneKey = paneKey
      @updatePaneVisiblityState paneKey, yes

  hidePane: (pane, paneKey) ->
    pane.unsetClass "active"

  showPane: (pane, paneKey) ->
    if paneKey is "chat"
      @chat.dock.emit "click"
    else
      pane.setClass "active"

  updatePaneVisiblityState: (paneKey, value) ->
    map          = @paneVisibilityState
    map[key]     = no for own key of map
    map[paneKey] = value

    @paneStateRef.set map

  createChatPane: ->
    @container.addSubView @chat = new ChatPane
      delegate : @panel.getDelegate()
      floating : yes

    @chat.on "WorkspaceChatClosed", =>
      @lastActivePaneKey = null
      @updatePaneVisiblityState "chat", no

  createTerminalPane: ->
    terminalClass = SharableTerminalPane
    terminalClass = SharableClientTerminalPane  if @isJoinedASession

    @container.addSubView @terminal = new KDView
      cssClass    : "floating-pane"
      size        : height : 400

    @terminal.addSubView @terminalPane = new terminalClass
      delegate    : @panel
      sessionKey  : @sessionKeys.terminal

    if @workspace.amIHost()
      @terminalPane.on "WebtermCreatead", =>
        @keysRef.child("terminal").set
          key     : @terminalPane.remote.session
          host    : KD.nick()
          vmName  : KD.getSingleton("vmController").defaultVmName

  createPreviewPane: ->
    @container.addSubView @preview = new KDView
      cssClass : "floating-pane floating-preview-pane"
      size     : height : 400
      partial  : """
        <div class="warning">
          <p>Type a URL to browse it with your friends.</p>
          <span>Note that, if you click links inside the page it can't be synced. You need to change the URL.</span>
        </div>
      """

    @previewPane  = new CollaborativePreviewPane
      delegate   : @panel
      sessionKey : @sessionKeys.preview

    if @workspace.amIHost()
      @workspace.on "WorkspaceSyncedWithRemote", =>
        @keysRef.child("preview").set @previewPane.sessionKey

    @preview.addSubView @previewPane

  resizePanes: (statesObj) ->
    activePanel = @workspace.getActivePanel()

    unless activePanel
      return @workspace.once "WorkspaceSyncedWithRemote", =>
        @resizePanes statesObj

    finder = activePanel.getPaneByName "finder"
    return unless finder

    finderContainer   = finder.container
    finderNeedsResize = no

    for own key, value of statesObj
      if key isnt "chat" and value is yes
        finderNeedsResize = yes

    return if not finderNeedsResize and not @finderResized

    if finderNeedsResize
      return if @finderResized
      finderContainer.setHeight finderContainer.getHeight() - 400
      @finderResized = yes
    else
      finderContainer.setHeight finderContainer.getHeight() + 400
      @finderResized = no

  getPaneByType: (type) ->
    return @[type] or null
