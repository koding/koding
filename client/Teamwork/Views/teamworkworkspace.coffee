class TeamworkWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    super options, data

    {playground, playgroundManifest} = @getOptions()
    @avatars = {}

    @on "PanelCreated", (panel) =>
      @createButtons panel
      @createRunButton panel  if playground

    @on "WorkspaceSyncedWithRemote", =>
      if playground and @amIHost()
        @workspaceRef.child("playground").set playground

        if playgroundManifest
          @workspaceRef.child("playgroundManifest").set playgroundManifest

    @on "WorkspaceUsersFetched", =>
      @workspaceRef.child("users").once "value", (snapshot) =>
        userStatus = snapshot.val()
        return unless userStatus
        @manageUserAvatars userStatus

    @on "NewHistoryItemAdded", (data) =>
      @sendSystemMessage data

    KD.singleton("windowController").addUnloadListener "window", =>
      @workspaceRef.remove()  if @amIHost()

    @chatView.sendWelcomeMessage()  if @amIHost()

  setWatchMode: (targetUsername) ->
    username = KD.nick()
    @watchRef.child(username).set targetUsername

  createButtons: (panel) ->
    panel.addSubView @buttonsContainer = new KDCustomHTMLView
      cssClass : "tw-buttons-container"

  displayBroadcastMessage: (options) ->
    super options

    if options.origin is "users"
      KD.utils.wait 500, => # prevent double triggered firebase event.
        @fetchUsers()

  startNewSession: (options) ->
    KD.mixpanel "User Started Teamwork session"
    @getDelegate().emit "NewSessionRequested", options

  joinSession: (newOptions) ->
    sessionKey              = newOptions.sessionKey.trim()
    options                 = @getOptions()
    options.sessionKey      = sessionKey
    options.joinedASession  = yes
    @destroySubViews()

    @forceDisconnect()
    @firebaseRef.child(sessionKey).once "value", (snapshot) =>
      value = snapshot.val()
      {playground, playgroundManifest} = value  if value

      teamworkClass     = TeamworkWorkspace
      teamworkOptions   = options

      if playground
        teamworkClass   = @getPlaygroundClass playground

      if playgroundManifest
        teamworkOptions = @getDelegate().mergePlaygroundOptions playgroundManifest

      teamworkOptions.sessionKey = newOptions.sessionKey

      teamwork                   = new teamworkClass teamworkOptions
      @getDelegate().teamwork    = teamwork
      @addSubView teamwork

  createRunButton: (panel) ->
  #   panel.headerButtonsContainer.addSubView new KDButtonView
  #     title      : "Run"
  #     cssClass   : "clean-gray tw-ply-run"
  #     callback   : => @handleRun panel

  getPlaygroundClass: (playground) ->
    return if playground is "Facebook" then FacebookTeamwork else PlaygroundTeamwork

  handleRun: (panel) ->
    console.warn "You should override this method."

  showHintModal: ->
    if @markdownContent
      @getDelegate().showMarkdownModal()
    else
      Panel::showHintModal.call @getActivePanel()

  manageUserAvatars: (users) ->
    for own nickname, data of users
      if data.status is "online"
        unless @avatars[nickname]
          @createUserAvatar @users[nickname]
      else
        if @avatars[nickname]
          @removeUserAvatar nickname

  createUserAvatar: (jAccount) ->
    return unless jAccount

    userNickname = jAccount.profile.nickname
    return if userNickname is KD.nick()
    followText   = "Click avatar to watch #{userNickname}"

    avatarView   = new AvatarStaticView
      size       :
        width    : 30
        height   : 30
      tooltip    :
        title    : followText
      click      : =>
        @watchingUserAvatar?.unsetClass "watching"
        isAlreadyWatched = @watchingUserAvatar is avatarView

        if isAlreadyWatched
          @watchRef.child(@nickname).set "nobody"
          message = "You stopped watching #{userNickname}"
          @watchingUserAvatar = null
          avatarView.setTooltip
            title : followText
        else
          @watchRef.child(@nickname).set userNickname
          message = "You started to watch #{userNickname}.  Type 'stop watching' or click on avatars to start/stop watching."
          avatarView.setClass "watching"
          @watchingUserAvatar = avatarView
          avatarView.setTooltip
            title : "You are now watching #{userNickname}. Click again to stop watching."

        @chatView.botReply message
    , jAccount

    @avatars[userNickname] = avatarView
    @avatarsView.addSubView avatarView
    @avatarsView.setClass "has-user"
    avatarView.bindTransitionEnd()

  removeUserAvatar: (nickname) ->
    avatarView = @avatars[nickname]
    avatarView.destroy()
    delete @avatars[nickname]
    @avatarsView.unsetClass "has-user" if @avatars.length is 0

  sendSystemMessage: (messageData) ->
    return unless @getOptions().enableChat
    @chatView.sendMessage messageData, yes

  toggleChatPane: ->
    cssClass      = "tw-chat-open"
    isChatVisible = @hasClass cssClass
    @toggleClass cssClass
    @chatButton.toggleClass "active"

    if isChatVisible then @chatView.hide() else @chatView.show()

  createLoader: ->
    @loader    = new KDView
      cssClass : "tw-loading"
      partial  : """
        <figure class="loading-animation">
          <span></span>
        </figure>
      """

    @container.addSubView @loader

  showImportModal: ->
    modal          = new KDModalView
      title        : "Import Content to your VM"
      cssClass     : "tw-modal tw-import-modal"
      overlay      : yes
      width        : 600
      buttons      :
        Import     :
          title    : "Import"
          cssClass : "modal-clean-green"
          icon     : yes
          iconClass: "tw-import-icon"
          callback : => @getDelegate().emit "ImportRequested", importUrlInput.getValue()
        Close      :
          title    : "Cancel"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

    modal.addSubView importUrlInput = new KDHitEnterInputView
      type         : "text tw-import-url"
      placeholder  : "Enter the URL of a git repository or zip archive."
      callback     : => @getDelegate().emit "ImportRequested", importUrlInput.getValue()

    modal.addSubView new KDCustomHTMLView
      tagName      : "span"
      cssClass     : "input-icon"
