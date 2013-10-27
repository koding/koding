class CollaborativeWorkspace extends Workspace

  init: ->
    @sessionData = []
    @users       = {}
    @createRemoteInstance()
    @createLoader()
    @fetchUsers()
    @createUserListContainer()
    @createChat()  if @getOptions().enableChat
    @bindRemoteEvents()

  createChat: ->
    @container.addSubView @chatView = new ChatPane delegate: this
    @chatView.hide()

  createRemoteInstance: ->
    instanceName  = @getOptions().firebaseInstance

    unless instanceName
      return warn "CollaborativeWorkspace requires a Firebase instance."

    @firepadRef   = new Firebase "https://#{instanceName}.firebaseIO.com/"
    @sessionKey   = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef = @firepadRef.child @sessionKey
    @historyRef   = @workspaceRef.child "history"

  bindRemoteEvents: ->
    @workspaceRef.once "value", (snapshot) =>
      if @getOptions().sessionKey
        unless snapshot.val()
          @showNotActiveView()
          return false

      isOldSession = keys = snapshot.val()?.keys

      if isOldSession
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

      initialMessage   = "$0 started a #{@getOptions().name} session. Session key is, #{@sessionKey}"
      if isOldSession
        initialMessage = "$0 joined."

      @setHistory initialMessage

      @emit "WorkspaceSyncedWithRemote"

    @workspaceRef.child("users").on "child_added", (snapshot) =>
      @fetchUsers()

    @workspaceRef.child("users").on "child_changed", (snapshot) =>
      @setHistory "#{snapshot.name()} is disconnected."

    @workspaceRef.on "child_removed", (snapshot) =>
      return  if @disconnectedModal
      # root node is write protected. however when someone try to remove root node
      # firebase will trigger disconnect event for once, which is a really wrong behaviour.
      # to be sure it's a real disconnection, trying to get node value again.
      # if we can't get the node value then it means user really disconnected.
      KD.utils.wait 1500, =>
        @workspaceRef.once "value", (snapshot) =>
          @showDisconnectedModal()  unless snapshot.val() or @disconnectedModal

    @on "AllPanesAddedToPanel", (panel, panes) ->
      paneSessionKeys = []
      paneSessionKeys.push pane.sessionKey for pane in panes
      @sessionData.push paneSessionKeys

    @on "KDObjectWillBeDestroyed", =>
      @forceDisconnect()
      @workspaceRef.off eventName for eventName in ["value", "child_added", "child_removed", "child_changed"]

  fetchUsers: ->
    @workspaceRef.once "value", (snapshot) =>
      val = snapshot.val()
      return  unless val

      usernames = []
      usernames.push username for own username, status of val.users unless @users[username]

      KD.remote.api.JAccount.some { "profile.nickname": { "$in": usernames } }, {}, (err, jAccounts) =>
        @users[user.profile.nickname] = user for user in jAccounts
        @emit "WorkspaceUsersFetched"

  createPanel: (callback = noop) ->
    panelOptions             = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate    = @
    panelOptions.sessionKeys = @sessionData[@lastCreatedPanelIndex]  if @sessionData
    panelClass               = @getOptions().panelClass or CollaborativePanel
    newPanel                 = new panelClass panelOptions

    @container.addSubView newPanel
    @panels.push newPanel
    @activePanel = newPanel

    callback()
    @emit "PanelCreated", newPanel

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return  "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

  getSessionOwner: ->
    return @sessionKey.split(":").first

  amIHost: ->
    [sessionOwner] = @sessionKey.split ":"
    return sessionOwner is KD.nick()

  showNotActiveView: ->
    notValid = new KDView
      cssClass : "not-valid"
      partial  : "This session is not valid or no longer available."

    notValid.addSubView new KDView
      cssClass : "description"
      partial  : "This usually means, the person who is hosting this session is disconnected or closed the session."

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
    @loader.on "viewAppended", -> loaderView.show()
    @container.addSubView @loader

  isJoinedASession: ->
    return  @getOptions().joinedASession

  joinSession: (newOptions) ->
    options                = @getOptions()
    options.sessionKey     = newOptions.sessionKey.trim()
    options.joinedASession = yes
    @destroySubViews()

    @forceDisconnect()

    @addSubView new CollaborativeWorkspace options

  forceDisconnect: ->
    return  unless @amIHost()
    @forcedToDisconnect = yes
    @workspaceRef.remove()
    KD.utils.wait 2000, => # check for user is still connected
      @forcedToDisconnect = no

  showDisconnectedModal: ->
    return if @forcedToDisconnect

    if @amIHost()
      title   = "Disconnected from remote"
      content = "It seems, you have been disconnected from Firebase server. You cannot continue this session."
    else
      title   = "Host disconnected"
      content = "It seems, host is disconnected from Firebase server. You cannot continue this session."

    @disconnectedModal = new KDBlockingModalView
      title            : title
      appendToDomBody  : no
      content          : "<p>#{content}</p>"
      cssClass         : "host-disconnected-modal"
      overlay          : no
      buttons          :
        Start          :
          title        : "Start New Session"
          callback     : =>
            @disconnectedModal.destroy()
            @startNewSession()
        Join           :
          title        : "Join Another Session"
          callback     : =>
            @disconnectedModal.destroy()
            @showJoinModal()
        Exit           :
          title        : "Exit App"
          cssClass     : "modal-cancel"
          callback     : =>
            @disconnectedModal.destroy()
            appManager = KD.getSingleton "appManager"
            appManager.quit appManager.frontApp

    @disconnectedModal.on "KDObjectWillBeDestroyed", =>
      delete @disconnectedModal
      @disconnectOverlay.destroy()

    @disconnectOverlay = new KDOverlayView
      parent           : KD.singletons.mainView.mainTabView.activePane
      isRemovable      : no

    @container.getDomElement().append @disconnectedModal.getDomElement()

  showJoinModal: ->
    options        = @getOptions()
    modal          = new KDModalView
      title        : options.joinModalTitle   or "Join New Session"
      content      : options.joinModalContent or "<p>This is your session key, you can share this key with your friends to work together.</p>"
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

  handleJoinASessionFromModal: (sessionKey, modal) ->
    return unless sessionKey
    @joinSession { sessionKey }
    modal.destroy()

  showShareView: (panel, workspace, event) ->
    button   = KD.instances[event.currentTarget.id]
    shareUrl = "#{location.origin}/Develop/#{@getOptions().name}?sessionKey=#{@sessionKey}"
    new JContextMenu
      cssClass    : "activity-share-popup"
      type        : "activity-share"
      delegate    : this
      x           : button.getX() + 25
      y           : button.getY() + 25
      arrow       :
        placement : "top"
        margin    : -10
      lazyLoad    : yes
    , customView  : new SharePopup {
        url       : shareUrl
        shortenURL: false
        twitter   :
          text    : "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{shareUrl}"
        linkedin  :
          title   : "Join me @koding!"
          text    : "Learn, code and deploy together to powerful VMs - @koding, the dev environment from the future! #{shareUrl}"
      }

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

    @historyRef.child(Date.now()).set { message, user }
