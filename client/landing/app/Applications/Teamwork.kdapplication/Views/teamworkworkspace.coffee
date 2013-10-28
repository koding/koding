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

  createLoader: ->
    @container.addSubView @loader = new KDCustomHTMLView
      cssClass   : "teamwork-loader"
      tagName    : "img"
      attributes :
        src      : "#{KD.apiUri}/images/teamwork/loading.gif"

  startNewSession: (options) ->
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
    warn "You should override this method."
