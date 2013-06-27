class CollaborativeTerminalPane extends TerminalPane

  constructor: (options = {}, data) ->

    super options, data

    @sessionKey  = @getOptions().sessionKey or @createSessionKey()


  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"
