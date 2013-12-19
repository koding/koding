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

      # if @amIHost()
      #   # currently only for host.
      #   # bc of clients need to know host's vmName and active pane's file data etc.
      #   activePanel    = @getActivePanel()
      #   {previewPane}  = activePanel.paneLauncher
      #   {viewerHeader} = previewPane.previewer
      #   viewerHeader.addSubView new KDButtonView
      #     cssClass : "clean-gray tw-previewer-button"
      #     title    : "View active file"
      #     callback : =>
      #       @previewFile()

      #   viewerHeader.addSubView @autoRefreshSwitch = new KDOnOffSwitch
      #     defaultValue : off
      #     cssClass     : "tw-live-update"
      #     title        : "Auto Refresh: "
      #     size         : "tiny"
      #     tooltip      :
      #       title      : "If it's on, preview will be refreshed when you save a file."
      #       placement  : "bottom"

      #   activePanel.getPaneByName("editor").on "EditorDidSave", =>
      #     @refreshPreviewPane previewPane  if @autoRefreshSwitch.getValue()

    @on "WorkspaceUsersFetched", =>
      @workspaceRef.child("users").once "value", (snapshot) =>
        userStatus = snapshot.val()
        return unless userStatus
        @manageUserAvatars userStatus

    @on "NewHistoryItemAdded", (data) =>
      # log data
      @sendSystemMessage data.message

  createButtons: (panel) ->
    panel.addSubView @buttonsContainer = new KDCustomHTMLView
      cssClass : "tw-buttons-container"

    @buttonsContainer.addSubView new KDButtonView
      iconClass: "tw-cog"
      iconOnly : yes
      callback : => @getDelegate().showToolsModal panel, this

  displayBroadcastMessage: (options) ->
    super options

    if options.origin is "users"
      KD.utils.wait 500, => # prevent double triggered firebase event.
        @fetchUsers()

  # createLoader: ->
  #   @container.addSubView @loader = new KDCustomHTMLView
  #     cssClass   : "teamwork-loader"
  #     tagName    : "img"
  #     attributes :
  #       src      : "#{KD.apiUri}/images/teamwork/loading.gif"

  startNewSession: (options) ->
    KD.mixpanel "User Started Teamwork session"

    @destroySubViews()
    unless options
      options = @getOptions()
      delete options.sessionKey

    workspaceClass          = @getPlaygroundClass options.playground
    teamwork                = new workspaceClass options
    @getDelegate().teamwork = teamwork
    @addSubView teamwork

  joinSession: (newOptions) ->
    sessionKey              = newOptions.sessionKey.trim()
    options                 = @getOptions()
    options.sessionKey      = sessionKey
    options.joinedASession  = yes
    @destroySubViews()

    @forceDisconnect()
    @firepadRef.child(sessionKey).once "value", (snapshot) =>
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

  refreshPreviewPane: (previewPane) ->
    # emitting ViewerRefreshed event will trigger refreshing the preview via Firebase.
    previewPane.previewer.emit "ViewerRefreshed"

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

  previewFile: ->
    activePanel     = @getActivePanel()
    editor          = activePanel.getPaneByName "editor"
    file            = editor.getActivePaneFileData()
    path            = FSHelper.plainPath file.path
    error           = "File must be under Web folder"
    isLocal         = path.indexOf("localfile") is 0
    isNotPublic     = not FSHelper.isPublicPath path
    {previewPane}   = activePanel.paneLauncher

    return if isLocal or isNotPublic
      error         = "This file cannot be previewed" if isLocal
      new KDNotificationView
        title       : error
        cssClass    : "error"
        type        : "mini"
        duration    : 2500
        container   : previewPane

    url = path.replace "/home/#{@getHost()}/Web", "https://#{KD.nick()}.kd.io"
    previewPane.openUrl url

  manageUserAvatars: (userStatus) ->
    for own nickname, status of userStatus
      if status is "online"
        unless @avatars[nickname]
          @createUserAvatar @users[nickname]
      else
        if @avatars[nickname]
          @removeUserAvatar nickname

  createUserAvatar: (jAccount) ->
    return unless jAccount

    userNickname = jAccount.profile.nickname
    return if userNickname is KD.nick()
    followText   = "Click user avatar to watch #{userNickname}"

    avatarView   = new AvatarStaticView
      size       :
        width    : 25
        height   : 25
      tooltip    :
        title    : followText
      click      : =>
        @watchingUserAvatar?.unsetClass "watching"
        isAlreadyWatched = @watchingUserAvatar is avatarView

        if isAlreadyWatched
          @watchRef.child(@nickname).set "nobody"
          message = "#{KD.nick()} stopped watching #{userNickname}"
          @watchingUserAvatar = null
          avatarView.setTooltip
            title : followText
        else
          @watchRef.child(@nickname).set userNickname
          message = "#{KD.nick()} started to watch #{userNickname}.  Type 'stop watching' or click on avatars to start/stop watching."
          avatarView.setClass "watching"
          @watchingUserAvatar = avatarView
          avatarView.setTooltip
            title : "You are now watching #{userNickname}. Click again to stop watching."

        message =
          user       :
            nickname : "teamwork"
          time       : Date.now()
          body       : message
        @workspaceRef.child("chat").child(message.time).set message
    , jAccount

    @avatars[userNickname] = avatarView
    @avatarsView.addSubView avatarView
    @avatarsView.setClass "has-user"
    avatarView.bindTransitionEnd()

  removeUserAvatar: (nickname) ->
    avatarView = @avatars[nickname]
    avatarView.setClass "fade-out"
    avatarView.once "transitionend", =>
      avatarView.destroy()
      delete @avatars[nickname]
      @avatarsView.unsetClass "has-user" if @avatars.length is 0

  sendSystemMessage: (message) ->
    message =
      user  : nickname : "teamwork"
      time  : Date.now()
      body  : message

    @chatView.chatRef.child(message.time).set message

  createActivityWidget: (panel) ->
    url = "#{KD.config.apiUri}/Teamwork?sessionKey=#{@sessionKey}"

    panel.addSubView @activityWidget = new ActivityWidget
      cssClass      : "tw-activity-widget collapsed"
      defaultValue  : "Would you like to join my Teamwork session? #{url}"
      childOptions  :
        cssClass    : "activity-item"

    @activityWidget.addSubView @notification = new KDCustomHTMLView
      cssClass  : "notification"
      partial   : "This status update will be visible in Activity feed."

    @activityWidget.addSubView new KDCustomHTMLView
      cssClass   : "close-tab"
      click      : =>
        @activityWidget.setClass "collapsed"
        @activityWidget.on "transitionend", =>
          @activityWidget.hide()

    panel.addSubView shareButton = new KDButtonView
      cssClass   : "tw-rounded-button share"
      title      : "Share"
      callback   : @bound "share"

    panel.addSubView @showActivityWidget = new KDButtonView
      cssClass   : "tw-show-activity-widget"
      iconOnly   : yes
      iconClass  : "icon"
      callback   : =>
        if @activityWidget.activity
          @activityWidget.show()
          @activityWidget.unsetClass "collapsed"
        else
          @share()

    @workspaceRef.child("activityId").once "value", (snapshot) =>
      return  unless id = snapshot.val()
      shareButton.hide()
      @notification.hide()
      @activityWidget.display id, =>
        @activityWidget.hideForm()

    @delegate.on "Exported", (name, url) =>
      @activityWidget.reply "#{KD.nick()} exported #{name} #{url}"

  share: ->
    @activityWidget.show()
    @activityWidget.unsetClass "collapsed"
    @activityWidget.showForm (err, activity) =>
      return  err if err
      @activityWidget.hideForm()
      @notification.hide()
      @workspaceRef.child("activityId").set activity.getId()
