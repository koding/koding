class CollaborativePane extends Pane

  constructor: (options, data) ->

    options.cssClass  = KD.utils.curry "ws-pane", options.cssClass

    super options, data

    @panel            = @getDelegate()
    @workspace        = @panel.getDelegate()
    @sessionKey       = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef     = @workspace.firepadRef.child @sessionKey
    @isJoinedASession = @getOptions().sessionKey
    @amIHost          = @workspace.amIHost()
    @container        = new KDView cssClass: "ws-container"

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}_#{u.generatePassword(4)}_#{u.getRandomNumber(100)}"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """