class TeamworkWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    super options, data

    {playground, playgroundManifest} = @getOptions()
    @avatars = {}

    @on "PanelCreated", (panel) =>
      @createButtons panel
      @createRunButton panel  if playground
      @getActivePanel().header.setClass "teamwork"
      @createActivityWidget panel

    @on "WorkspaceSyncedWithRemote", =>
      if playground and @amIHost()
        @workspaceRef.child("playground").set playground

        if playgroundManifest
          @workspaceRef.child("playgroundManifest").set playgroundManifest

      @hidePlaygroundsButton()  unless @amIHost()

      @workspaceRef.child("users").on "child_added", (snapshot) =>
        joinedUser = snapshot.name()
        return if not joinedUser or joinedUser is KD.nick()
        @hidePlaygroundsButton()

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

  createButtons: (panel) ->
    panel.addSubView @buttonsContainer = new KDCustomHTMLView
      cssClass : "tw-buttons-container"

    @buttonsContainer.addSubView @chatButton = new KDButtonView
      cssClass : "tw-chat-toggle active"
      iconClass: "tw-chat"
      iconOnly : yes
      callback : =>
        cssClass      = "tw-chat-open"
        isChatVisible = @hasClass cssClass
        @toggleClass cssClass
        @chatButton.toggleClass "active"

        if isChatVisible then @chatView.hide() else @chatView.show()

    @buttonsContainer.addSubView @shareButton = new KDButtonView
      iconClass: "tw-export"
      iconOnly : yes
      # callback : => @createShareMenuButton()
      callback : => @getDelegate().emit "ExportRequested"

    @buttonsContainer.addSubView @optionsButton = new KDButtonView
      iconClass: "tw-cog"
      iconOnly : yes
      callback : => @createOptionsMenuButton()

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
    panel.headerButtonsContainer.addSubView new KDButtonView
      title      : "Run"
      cssClass   : "clean-gray tw-ply-run"
      callback   : => @handleRun panel

  getPlaygroundClass: (playground) ->
    return if playground is "Facebook" then FacebookTeamwork else PlaygroundTeamwork

  handleRun: (panel) ->
    console.warn "You should override this method."

  hidePlaygroundsButton: ->
    @getActivePanel().headerButtons.Playgrounds?.hide()

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

  createOptionsMenuButton: ->
    menuItems = [
      { title : "Join in", callback : => @showJoinModal()   }
      { title : "Import" , callback : => @showImportModal() }
      { title : "Team up", callback : => @getDelegate().showTeamUpModal() }
    ]

    @createMenuButton @optionsButton.$().offset(), menuItems

  createShareMenuButton: ->
    menuItems = [
      { title : "Share",   callback : => console.log "join in" }
      { title : "Export" , callback : => @getDelegate().emit "ExportRequested" }
    ]

    @createMenuButton @shareButton.$().offset(), menuItems

  createMenuButton: (offset, items) ->
    new JContextMenu
      x           : offset.left - 140
      y           : offset.top  + 31
      arrow       :
        placement : "top"
        margin    : 150
    , items

  createActivityWidget: (panel) ->
    panel.addSubView @activityWidget = new ActivityWidget
      cssClass      : "tw-activity-widget collapsed"
      childOptions  :
        cssClass    : "activity-item"

    @activityWidget.addSubView @notification = new KDCustomHTMLView
      cssClass  : "notification"
      partial   : "This status update will be visible in Activity feed."

    @activityWidget.addSubView new KDCustomHTMLView
      cssClass   : "close-tab"
      click      : @bound "hideActivityWidget"

    panel.addSubView @inviteTeammate = new KDButtonView
      cssClass : "invite-teammate tw-rounded-button hidden"
      title    : "Invite"
      callback : =>
        url = "#{KD.config.apiUri}/Teamwork?sessionKey=#{@sessionKey}"
        @activityWidget.setInputContent "Join me in Teamwork: #{url}"
        @showActivityWidget()
        @hideShareButtons()
        @activityWidget.showForm (err, activity) =>
          return  err if err
          @activityWidget.hideForm()
          @notification.hide()
          @workspaceRef.child("activityId").set activity.getId()

        KD.mixpanel "Teamwork Invite, click", {@sessionKey}

    panel.addSubView @exportWorkspace = new KDButtonView
      cssClass : "export-workspace tw-rounded-button hidden"
      title    : "Export"
      callback : =>
        @getDelegate().emit "ExportRequested", (name, url) =>
        @hideShareButtons()

        KD.mixpanel "Teamwork Export, click"

    panel.addSubView shareButton = new KDButtonView
      cssClass   : "tw-rounded-button share"
      title      : "Share"
      callback   : =>
        @inviteTeammate.toggleClass "hidden"
        @exportWorkspace.toggleClass "hidden"

        KD.mixpanel "Teamwork Share, click"

    panel.addSubView @showActivityWidgetButton = new KDButtonView
      cssClass   : "tw-show-activity-widget"
      iconOnly   : yes
      iconClass  : "icon"
      callback   : =>
        if @activityWidget.activity
          @activityWidget.hideForm()
          @showActivityWidget()
        else
          @share()

    {activityId} = @getOptions()
    if activityId then @displayActivity activityId
    else
      @workspaceRef.child("activityId").once "value", (snapshot) =>
        return  unless activityId = snapshot.val()
        @displayActivity activityId

    @getDelegate().on "Exported", (name, importUrl) =>
      activityId = @activityWidget.activity?.getId()

      query = {import: importUrl}
      query.activityId = activityId  if activityId
      querystring = @utils.stringifyQuery query

      @utils.shortenUrl "#{KD.config.apiUri}/Teamwork?#{querystring}", (url) =>
        message = "#{KD.nick()} exported #{name} #{url}"
        if activityId then @activityWidget.reply message
        else
          @activityWidget.setInputContent message
          @showActivityWidget()

  showActivityWidget: ->
    @activityWidget.show()
    @activityWidget.unsetClass "collapsed"

  hideActivityWidget: ->
    @activityWidget.setClass "collapsed"
    @activityWidget.on "transitionend", =>
      @activityWidget.hide()

  showShareButtons: ->
    @inviteTeammate.show()
    @exportWorkspace.show()

  hideShareButtons: ->
    @inviteTeammate.hide()
    @exportWorkspace.hide()

  displayActivity: (id) ->
    @activityWidget.display id, =>
      @notification.hide()
      @activityWidget.hideForm()

  share: ->
    @activityWidget.show()
    @activityWidget.unsetClass "collapsed"

    if @activityWidget.activity
      @activityWidget.hideForm()
    else
      @activityWidget.showForm (err, activity) =>
        return  err if err
        @activityWidget.hideForm()
        @notification.hide()
        @workspaceRef.child("activityId").set activity.getId()

  createLoader: ->
    @loader    = new KDView
      cssClass : "tw-loader pulsing"

    @container.addSubView @loader

  showImportModal: ->
    modal          = new KDModalView
      title        : "Import Content to your VM"
      content      : "<p>Enter the URL of a git repository or zip archive.</p>"
      cssClass     : "workspace-modal join-modal"
      overlay      : yes
      width        : 600
      buttons      :
        Import     :
          title    : "Import"
          cssClass : "modal-clean-green"
          callback : => @getDelegate().emit "ImportRequested", importUrlInput.getValue()
        Close      :
          title    : "Close"
          cssClass : "modal-cancel"
          callback : -> modal.destroy()

    modal.addSubView importUrlInput = new KDHitEnterInputView
      type         : "text"
      placeholder  : "Import Url"
      callback     : => @handleJoinASessionFromModal sessionKeyInput.getValue(), modal
