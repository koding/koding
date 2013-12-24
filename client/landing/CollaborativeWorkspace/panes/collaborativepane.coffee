class CollaborativePane extends Pane

  constructor: (options, data) ->

    options.cssClass  = KD.utils.curry "ws-pane", options.cssClass

    super options, data

    @panel            = @getDelegate()
    @workspace        = @panel.getDelegate()
    @sessionKey       = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef     = @workspace.firebaseRef.child @sessionKey
    @isJoinedASession = @getOptions().sessionKey
    @amIHost          = @workspace.amIHost()
    @container        = new KDView cssClass: "ws-container"

    # This is too much risky line, blame this line first if something become wrong
    @workspaceRef.onDisconnect().remove()  if @amIHost

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}_#{u.generatePassword(4)}_#{u.getRandomNumber(100)}"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """
