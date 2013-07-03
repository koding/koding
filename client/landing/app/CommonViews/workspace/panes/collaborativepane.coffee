class CollaborativePane extends Pane

  constructor: (options = {}, data) ->

    super options, data

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"