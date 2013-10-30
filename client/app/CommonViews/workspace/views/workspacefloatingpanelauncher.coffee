class WorkspaceFloatingPaneLauncher extends KDCustomHTMLView

  constructor: (options = {}, data) ->

    options.cssClass = "workspace-launcher"
    options.partial  = "<span>+</span>"

    super options, data

    @sessionKeys      = {}
    @panel            = @getDelegate()
    @workspace        = @panel.getDelegate()
    @container        = new KDView cssClass: "workspace-floating-panes"
    @keysRef          = @workspace.workspaceRef.child "floatingPaneKeys"
    @isJoinedASession = @workspace.getOptions().joinedASession

    @panel.addSubView @container

    if @isJoinedASession
      @keysRef.once "value", (snapshot) =>
        @sessionKeys = snapshot.val()
        @createPanes()
    else
      @createPanes()

  click: ->
    @createPanes()  unless @panesCreated
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
    pane = @[paneKey]
    pane.setClass "active"

    KD.getSingleton("windowController").addLayer pane
    pane.on "ReceivedClickElsewhere", =>
      pane.unsetClass "active"

  createChatPane: ->
    @container.addSubView @chat = new ChatPane
      delegate : @panel.getDelegate()
      floating : yes

  createTerminalPane: ->
    terminalClass    = SharableTerminalPane
    terminalClass    = SharableClientTerminalPane  if @isJoinedASession

    @container.addSubView @terminal = new KDView
      cssClass   : "floating-pane"
      size       : height : 400

    @terminal.addSubView @terminalPane = new terminalClass
      delegate   : @panel
      sessionKey : @sessionKeys.terminal

    @terminalPane.webterm.on "WebTermConnected", =>
      @keysRef.child("terminal").set
        key    : @terminalPane.remote.session
        host   : KD.nick()
        vmName : KD.getSingleton("vmController").defaultVmName

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

    @workspace.on "WorkspaceSyncedWithRemote", =>
      @keysRef.child("preview").set @previewPane.sessionKey

    @preview.addSubView @previewPane

  getPaneByType: (type) ->
    return @[type] or null
