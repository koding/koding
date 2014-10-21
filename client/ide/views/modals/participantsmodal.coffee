class IDE.ParticipantsModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'ide-participants-modal'
    options.title    = "#{options.host}'s session"
    options.overlay  = yes

    super options, data

    { @participants, @realTimeDoc, @rtm, @host } = options

    @createParticipantsList()

  createParticipantsList: ->

    @participants.asArray().forEach (participant) =>
      @addSubView new IDE.ParticipantView { participant, @realTimeDoc, @rtm, @host }
