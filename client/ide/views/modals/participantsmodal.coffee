class IDE.ParticipantsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'ide-participants-modal'
    options.title    = "#{options.host}'s session"
    options.overlay  = yes

    super options, data

    { @participants, @rtm, @host } = options

    @participantViews = []

    @createParticipantsList()
    @markParticipantsAsWatching()


  createParticipantsList: ->

    @participants.asArray().forEach (participant) =>
      view = new IDE.ParticipantView { participant, @rtm, @host }

      @participantViews.push view
      @addSubView view

      @forwardEvent view, 'ParticipantWatchRequested'


  markParticipantsAsWatching: ->
    # TODO: Presence check before marking participant

    nick = KD.nick()
    map  = @rtm.getFromModel "#{nick}WatchMap"

    return unless map

    watchings = map.keys()

    for participantView in @participantViews
      {nickname} = participantView.getOption 'participant'

      if nickname in watchings
        participantView.watchButton.setTitle 'Watching'
