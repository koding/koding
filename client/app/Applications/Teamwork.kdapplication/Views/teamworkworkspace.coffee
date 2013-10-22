class TeamworkWorkspace extends CollaborativeWorkspace

  createLoader: ->
    @container.addSubView @loader = new KDCustomHTMLView
      cssClass   : "teamwork-loader"
      tagName    : "img"
      attributes :
        src      : "#{KD.apiUri}/images/teamwork/loading.gif"

  startNewSession: ->
    @destroySubViews()
    options  = @getOptions()
    delete options.sessionKey
    teamwork = new TeamworkWorkspace options
    @getDelegate().teamwork = teamwork
    @addSubView teamwork

  joinSession: (sessionKey) ->
    options                = @getOptions()
    options.sessionKey     = sessionKey.trim()
    options.joinedASession = yes
    @destroySubViews()

    @forceDisconnect()

    @addSubView new TeamworkWorkspace options
