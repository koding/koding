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
    return unless @getOptions().enableChat
    @chatView.sendMessage message, yes

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
        @activityWidget.setInputContent "Would you like to join my Teamwork session? #{url}"
        @showActivityWidget()
        @hideShareButtons()

    panel.addSubView @exportWorkspace = new KDButtonView
      cssClass : "export-workspace tw-rounded-button hidden"
      title    : "Export"
      callback : =>
        @getDelegate().emit "ExportRequested", (name, url) =>
        @hideShareButtons()

    panel.addSubView shareButton = new KDButtonView
      cssClass   : "tw-rounded-button share"
      title      : "Share"
      callback   : =>
        @inviteTeammate.toggleClass "hidden"
        @exportWorkspace.toggleClass "hidden"

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
