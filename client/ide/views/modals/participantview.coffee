class IDE.ParticipantView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = 'ide-participant'

    super options, data

    {participant, realTimeDoc, rtm, host} = options

    isHost   = host is participant.nickname
    isMe     = participant.nickname is KD.nick()
    hostText = if isHost then '<span>(Host)</span>' else ''

    @addSubView avatar = new AvatarView
      origin : participant.nickname
      size   : width: 46, height: 46

    @addSubView name = new KDCustomHTMLView
      cssClass   : 'name'
      partial    : "#{participant.nickname} #{hostText}"

    unless isMe

      @addSubView state = new KDCustomHTMLView
        partial  : 'Working on: '
        cssClass : 'open-panes'

      changes = rtm.getFromModel(realTimeDoc, "#{participant.nickname}Snapshot").values()
      terminalCounter = 1

      changes.forEach (change, i) ->
        return if not change.type or not change.context

        {type, context: { file, paneType, hash }} = change

        if type is 'NewPaneCreated' and paneType is 'editor'
          state.addSubView new KDCustomHTMLView
            tagName: 'span'
            partial: FSHelper.getFileNameFromPath file.path


      @addSubView @watchButton = new KDButtonView
        title      : 'Watch'
        cssClass   : 'solid compact green'
        callback   : =>
          title = if @watchButton.getTitle() is 'Watching' then 'Watch' else 'Watching'
          @watchButton.setTitle title
          @emit 'ParticipantWatchRequested', participant

    else
      @addSubView new KDCustomHTMLView
        cssClass   : 'thats-me'
        partial    : "That's you. Choose a participant to watch their changes."
