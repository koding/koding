class TeamworkWorkspace extends CollaborativeWorkspace

  constructor: (options = {}, data) ->

    super options, data

    {environment, environmentManifest} = @getOptions()

    @on "PanelCreated", (panel) =>
      @createRunButton panel  if environment

    @on "WorkspaceSyncedWithRemote", =>
      if environment and @amIHost()
        @workspaceRef.child("environment").set environment

        if environmentManifest
          @workspaceRef.child("environmentManifest").set environmentManifest

      @hidePlaygroundsButton()  unless @amIHost()

      usersRef = @workspaceRef.child "users"

      usersRef.on "child_added", (snapshot) =>
        joinedUser = snapshot.name()
        return if not joinedUser or joinedUser is KD.nick()
        @hidePlaygroundsButton()


      if @amIHost()
        # currently only for host.
        # bc of clients need to know host's vmName and active pane's file data etc.
        activePanel    = @getActivePanel()
        {previewPane}  = activePanel.paneLauncher
        {viewerHeader} = previewPane.previewer
        viewerHeader.addSubView new KDButtonView
          cssClass : "clean-gray tw-previewer-button"
          title    : "View active file"
          callback : =>
            @previewFile()

        viewerHeader.addSubView @autoRefreshSwitch = new KDOnOffSwitch
          defaultValue : off
          cssClass     : "tw-live-update"
          title        : "Auto Refresh: "
          size         : "tiny"
          tooltip      :
            title      : "If it's on, preview will be refreshed when you save a file."
            placement  : "bottom"
          callback     : (state) =>
            @refreshPreviewPane previewPane  if state

        activePanel.getPaneByName("editor").on "EditorDidSave", =>
          @refreshPreviewPane previewPane  if @autoRefreshSwitch.getValue()

  createLoader: ->
    @container.addSubView @loader = new KDCustomHTMLView
      cssClass   : "teamwork-loader"
      tagName    : "img"
      attributes :
        src      : "#{KD.apiUri}/images/teamwork/loading.gif"

  startNewSession: (options) ->
    KD.mixpanel "User Started Teamwork session"

    @destroySubViews()
    unless options
      options = @getOptions()
      delete options.sessionKey

    workspaceClass          = @getEnvironmentClass options.environment
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
      {environment, environmentManifest} = value  if value

      teamworkClass     = TeamworkWorkspace
      teamworkOptions   = options

      if environment
        teamworkClass   = @getEnvironmentClass environment

      if environmentManifest
        teamworkOptions = @getDelegate().mergeEnvironmentOptions environmentManifest

      teamworkOptions.sessionKey = newOptions.sessionKey

      teamwork                   = new teamworkClass teamworkOptions
      @getDelegate().teamwork    = teamwork
      @addSubView teamwork

  refreshPreviewPane: (previewPane) ->
    # emitting ViewerRefreshed event will trigger refreshing the preview via Firebase.
    previewPane.previewer.emit "ViewerRefreshed"

  createRunButton: (panel) ->
    # panel.headerButtons.Environments.hide()
    panel.header.addSubView new KDButtonView
      title      : "Run"
      callback   : => @handleRun panel

  getEnvironmentClass: (environment) ->
    switch environment
      when "Facebook" then FacebookTeamwork
      when "GoLang"   then GoLangTeamwork
      else TeamworkWorkspace

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
    {defaultVmName} = KD.getSingleton "vmController"

    return if isLocal or isNotPublic
      error         = "This file cannot be previewed" if isLocal
      new KDNotificationView
        title       : error
        cssClass    : "error"
        type        : "mini"
        duration    : 2500
        container   : previewPane

    url = path.replace "/home/#{@getHost()}/Web", defaultVmName
    previewPane.openUrl url
