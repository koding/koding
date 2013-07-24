class CollaborativeWorkspace extends Workspace

  constructor: (options = {}, data) ->

    super options, data

    @sessionData    = []
    instances       = @getOptions().firebaseInstances

    return warn "CollaborativeWorkspace requires at least one Firebase instance." unless instances

    currentInstance = instances
    currentInstance = instances[KD.utils.getRandomNumber(instances.length) - 1] if Array.isArray instances
    @firepadRef     = new Firebase "https://#{currentInstance}.firebaseIO.com/"
    @sessionKey     = options.sessionKey or @createSessionKey()
    @workspaceRef   = @firepadRef.child @sessionKey
    @historyRef     = @workspaceRef.child "history"
    @users          = {}

    @createUserListContainer()
    @createLoader()

    if @getOptions().enableChat
      @container.addSubView @chatView = new ChatPane
        delegate: this
      @chatView.hide()

    @workspaceRef.once "value", (snapshot) =>
      if @getOptions().sessionKey
        unless snapshot.val()
          @showNotActiveView()
          return false


      keys = snapshot.val()?.keys

      if keys # if we have keys this means we're about to join an old session
        @sessionData  = keys
        @createPanel()
        @userRef = @workspaceRef.child("users").child KD.nick()
        @userRef.set "online"
        @userRef.onDisconnect().set "offline"
      else
        @createPanel()
        @workspaceRef.set "keys": @sessionData
        @userRef = @workspaceRef.child("users").child KD.nick()
        @userRef.set "online"
        @userRef.onDisconnect().set "offline"

      if @amIHost()
        @workspaceRef.onDisconnect().remove()
        @userRef.onDisconnect().remove()

      @loader.destroy()
      @chatView?.show()

    @workspaceRef.on "child_added", (snapshot) =>

    @workspaceRef.child("users").on "child_added", (snapshot) =>
      @fetchUsers()

    @workspaceRef.on "child_changed", (snapshot) =>

    @workspaceRef.on "child_removed", (snapshot) =>
      @showDisconnectedModal()  unless @disconnectedModal

    @on "AllPanesAddedToPanel", (panel, panes) ->
      paneSessionKeys = []
      paneSessionKeys.push pane.sessionKey for pane in panes
      @sessionData.push paneSessionKeys

    @fetchUsers()

  fetchUsers: ->
    @workspaceRef.once "value", (snapshot) =>
      val = snapshot.val()
      return  unless val

      usernames = []
      usernames.push username for username, status of val.users unless @users[username]

      KD.remote.api.JAccount.some { "profile.nickname": { "$in": usernames } }, {}, (err, jAccounts) =>
        @users[user.profile.nickname] = user for user in jAccounts
        @emit "WorkspaceUsersFetched"

  createPanel: (callback = noop) ->
    panelOptions             = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate    = @
    panelOptions.sessionKeys = @sessionData[@lastCreatedPanelIndex]  if @sessionData
    newPanel                 = new CollaborativePanel panelOptions

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
    options        = @getOptions()
    modal          = new KDModalView
      title        : options.joinModalTitle   or "Join New Session"
      content      : options.joinModalContent or "This is your session key, you can share this key with your friends to work together."
      overlay      : yes
      cssClass     : "workspace-modal join-modal"
      width        : 500
      buttons      :
        Join       :
          title    : "Join Session"
          cssClass : "modal-clean-green"
          callback : => @handleJoinASessionFromModal sessionKeyInput.getValue(), modal
        Close      :
          title    : "Close"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

    modal.addSubView sessionKeyInput = new KDHitEnterInputView
      type         : "text"
      placeholder  : "Paste new session key and hit enter to join"
      callback     : => @handleJoinASessionFromModal sessionKeyInput.getValue(), modal

    callback modal

  handleJoinASessionFromModal: (sessionKey, modal) ->
    return unless sessionKey
    @joinSession sessionKey
    modal.destroy()

  createUserListContainer: ->
    @container.addSubView @userListContainer = new KDView
      cssClass : "user-list"

    @userListContainer.bindTransitionEnd()

  showUsers: ->
    return  if @userList
    @userListContainer.setClass "active"

    @userListContainer.addSubView @userList = new CollaborativeWorkspaceUserList {
      @workspaceRef
      @sessionKey
      container : @userListContainer
      delegate  : @
    }

  setHistory: (message = "") ->
    user    = KD.nick()
    message = message.replace "$0", user

    @historyRef.child(Date.now()).set {
      message
      user
    }