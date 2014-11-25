class IDE.ChatMessagePane extends PrivateMessagePane

  constructor: (options = {}, data)->

    options.cssClass = 'privatemessage'

    super options, data

    @addSubView @back = new KDButtonView
      title    : 'settings'
      cssClass : 'solid green mini'
      callback : => @getDelegate().showSettingsPane()

    @back.setStyle
      position : 'absolute'
      top      : '16px'
      right    : '16px'
      'z-index': 12

    @on 'AddedParticipant', @bound 'participantAdded'


  createInputWidget: ->

    channel = @getData()
    @input  = new ReplyInputWidget {channel, collaboration : yes, cssClass : 'private'}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  participantAdded: (participant) ->

    appManager = KD.getSingleton 'appManager'
    appManager.tell 'IDE', 'setMachineUser', participant
