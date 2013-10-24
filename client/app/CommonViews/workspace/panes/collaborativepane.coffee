class CollaborativePane extends Pane

  constructor: (options, data) ->

    super options, data

    @panel            = @getDelegate()
    @workspace        = @panel.getDelegate()
    @sessionKey       = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef     = @workspace.firepadRef.child @sessionKey
    @isJoinedASession = @getOptions().sessionKey
    @amIHost          = @workspace.amIHost()
    @container        = new KDView

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """