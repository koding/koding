class CollaborativeWorkspace extends Workspace

  constructor: (options = {}, data) ->

    super options, data

    @sessionData       = []
    @firepadRef        = new Firebase "https://workspace.firebaseIO.com/"
    workspaceId        = options.workspaceId or @createSessionKey()
    @workspaceRef      = @firepadRef.child workspaceId
    @isNewSession      = no
    @isNeedToSave      = yes

    @workspaceRef.on "value", (snapshot) =>
      return unless @isNeedToSave
      log "everything is something happened", "value", snapshot.val(), snapshot.name()

      keys         = snapshot.val()?.keys
      isOldSession = keys and not @isNewSession

      if isOldSession
        log "it's an old session, impressed!"
        @isNewSession = no
        @sessionData  = keys
        @createPanel()
      else
        log "your awesome new session, saving keys now"
        @isNewSession = yes
        @createPanel()
        @isNeedToSave = no
        @workspaceRef.set "keys": @sessionData

    @workspaceRef.on "child_added", (snapshot) =>
      log "everything is something happened", "child_added", snapshot.val(), snapshot.name()

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

    callback()

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return  "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

  ready: ->