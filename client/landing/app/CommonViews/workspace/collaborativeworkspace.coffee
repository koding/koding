class CollaborativeWorkspace extends Workspace

  constructor: (options = {}, data) ->

    super options, data

    @sessionData       = []
    @firepadRef        = new Firebase "https://hulogggg.firebaseIO.com/"
    @sessionKey        = options.sessionKey or @createSessionKey()
    @workspaceRef      = @firepadRef.child @sessionKey

    @createUserListContainer()
    @createLoader()

    @workspaceRef.once "value", (snapshot) =>
      if @getOptions().sessionKey
        log "user wants to join a session"
        unless snapshot.val()
          log "session is not active"
          @showNotActiveView()
          return false

        log "session is valid, trying to recover"

      log "everything is something happened", "value", snapshot.val(), snapshot.name()

      keys = snapshot.val()?.keys

      if keys # if we have keys this means we're about to join an old session
        log "it's an old session, impressed!"
        @sessionData  = keys
        @createPanel()
        @userRef = @workspaceRef.child("users").child KD.nick()
        @userRef.set "online"
        @userRef.onDisconnect().set "offline"
      else
        log "your awesome new session, saving keys now"
        @createPanel()
        @workspaceRef.set "keys": @sessionData
        @userRef = @workspaceRef.child("users").child KD.nick()
        @userRef.set "online"
        @userRef.onDisconnect().set "offline"

      if @amIHost()
        @workspaceRef.onDisconnect().remove()
        @userRef.onDisconnect().remove()

      @loader.destroy()

    @workspaceRef.on "child_added", (snapshot) =>
      log "everything is something happened", "child_added", snapshot.val(), snapshot.name()

    @workspaceRef.on "child_changed", (snapshot) =>
      log "everything is something happened", "child_changed", snapshot.val(), snapshot.name()

    @workspaceRef.on "child_removed", (snapshot) =>
      log "possible disconnection occured"

      @showDisconnectedModal()  unless @disconnectedModal

    @on "NewPanelAdded", (panel) ->
      log "New panel created", panel

    @on "AllPanesAddedToPanel", (panel, panes) ->
      paneSessionKeys = []
      paneSessionKeys.push pane.sessionKey for pane in panes
      @sessionData.push paneSessionKeys

  createPanel: (callback = noop) ->
    panelOptions             = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate    = @
    panelOptions.sessionKeys = @sessionData[@lastCreatedPanelIndex]  if @sessionData
    newPanel                 = new CollaborativePanel panelOptions

    log "instantiated a panel with these session keys", panelOptions.sessionKeys

    @container.addSubView newPanel
    @panels.push newPanel
    @activePanel = newPanel

    callback()
    @emit "PanelCreated"

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return  "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

  ready: -> # have to override for collaborative workspace

  amIHost: ->
    [sessionOwner] = @sessionKey.split ":"
    return sessionOwner is KD.nick()

  showNotActiveView: ->
    notValid = new KDView
      cssClass : "not-valid"
      partial  : "This session is not valid or no longer available."

    notValid.addSubView new KDView
      cssClass : "description"
      partial  : """
        If there is nothing wrong with our servers, this usually means,
        the person who is hosting this session is disconnected or closed the session.
      """

    notValid.addSubView new KDButtonView
      cssClass : "cupid-green"
      title    : "Start New Session"
      callback : @bound "startNewSession"

    @container.addSubView notValid
    @loader.hide()

  startNewSession: ->
    @destroySubViews()
    options = @getOptions()
    delete options.sessionKey
    @addSubView new CollaborativeWorkspace options

  createLoader: ->
    @loader    = new KDView
      cssClass : "workspace-loader"
      partial  : """<span class="text">Loading...<span>"""

    @loader.addSubView loaderView = new KDLoaderView size: width : 36
    @container.addSubView @loader
    @loader.on "viewAppended", -> loaderView.show()

  joinSession: (sessionKey) ->
    {parent}           = @
    options            = @getOptions()
    options.sessionKey = sessionKey
    @destroy()

    # TODO: fatihacet - temp fix to resize split view for users that joined a new session
    workspace = new CollaborativeWorkspace options
    workspace.on "PanelCreated", =>
      workspace.activePanel.splitView.resizePanel "20%", 0
    parent.addSubView workspace

    log "user joined a new session:", sessionKey

  showDisconnectedModal: ->
    if @amIHost()
      title   = "Disconnected from remote"
      content = "It seems, you have been disconnected from Firebase server. You cannot continue this session."
    else
      title   = "Host disconnected"
      content = "It seems, host is disconnected from Firebase server. You cannot continue this session."

    @disconnectedModal = new KDBlockingModalView
      title        : title
      content      : "<p>#{content}</p>"
      cssClass     : "host-disconnected-modal"
      overlay      : yes
      buttons      :
        Start      :
          title    : "Start New Session"
          callback : =>
            @disconnectedModal.destroy()
            delete @disconnectedModal
            @startNewSession()
        Join       :
          title    : "Join Another Session"
          callback : =>
            @disconnectedModal.destroy()
            delete @disconnectedModal
            @showSessionModal (modal) ->
              modal.modalTabs.showPaneByIndex(1)
        Exit       :
          title    : "Exit App"
          cssClass : "modal-cancel"
          callback : =>
            @disconnectedModal.destroy()
            delete @disconnectedModal
            appManager = KD.getSingleton("appManager")
            appManager.quit appManager.frontApp

  showJoinModal: (callback = noop) ->
    modal                 = new KDModalView
      title               : "Join New Session"
      content             : @getOptions().joinModalContent or ""
      overlay             : yes
      cssClass            : "workspace-modal join-modal"
      width               : 500
      buttons             :
        Join              :
          title           : "Join Session"
          cssClass        : "modal-clean-green"
          callback        : =>
            @handleJoinASessionFromModal sessionKeyInput.getValue(), modal
        Close             :
          title           : "Close"
          cssClass        : "modal-cancel"
          callback        : -> modal.destroy()

    modal.addSubView sessionKeyInput = new KDHitEnterInputView
      type        : "text"
      placeholder : "Paste new session key and hit enter to join"
      callback    : =>
        @handleJoinASessionFromModal sessionKeyInput.getValue(), modal

    callback modal

  handleJoinASessionFromModal: (sessionKey, modal) ->
    return unless sessionKey
    @joinSession sessionKey
    modal.destroy()

  showShareModal: (callback = noop) ->
    modal           = new KDModalView
      title         : "Share Your Session"
      content       : @getOptions().shareModalContent or ""
      overlay       : yes
      cssClass      : "workspace-modal share-modal"
      width         : 500
      buttons       :
        "Ok"        :
          title     : "OK"
          cssClass  : "modal-clean-green"
          callback  : -> modal.destroy()

    modal.addSubView input = new KDInputView
      defaultValue  : @sessionKey
      cssClass      : "key"
      attributes    :
        readonly    : "readonly"

    @utils.wait 300, -> input.$().focus().select()

    callback modal

  createUserListContainer: ->
    @container.addSubView @userListContainer = new KDView
      cssClass : "user-list"
    @userListContainer.bindTransitionEnd()

  showUsers: ->
    return  if @userListVisible

    @userListContainer.setClass "active"

    @userListContainer.addSubView new CollaborativeWorkspaceUserList {
      @workspaceRef
      @sessionKey
      container : @userListContainer
      delegate  : @
    }
    @userListVisible = yes