class CollaborativeWorkspace extends Workspace

  constructor: (options = {}, data) ->

    @firepadRef   = new Firebase "https://workspace.firebaseIO.com/"
    workspaceId   = options.workspaceId or @createSessionId()
    @workspaceRef = @firepadRef.child workspaceId

    # @workspaceRef.set { "data": x }

    # @workspaceRef.on "child_added", (s) =>
    #   log "something fetched", s.val(), s.name(), s.child("jedi").val()

    super options, data

    @on "NewPanelAdded", (panel) =>
      log "New panel created" panel

  createSessionId: ->
    nick = KD.nick()
    u    = KD.utils
    return  "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

CollaborativeWorkspace::PanelClass = CollaborativePanel