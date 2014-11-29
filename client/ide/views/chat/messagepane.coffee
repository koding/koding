class IDE.ChatMessagePane extends PrivateMessagePane

  constructor: (options = {}, data)->

    options.cssClass = 'privatemessage'

    super options, data

    @on 'AddedParticipant', @bound 'participantAdded'

    # forward this event to channel, so that
    # it can change in other views as well.
    # Kind of observable. ~Umut
    @on 'AddedParticipant', (participant) =>
      channel = @getData()
      channel.emit 'AddedToChannel', participant


  createParticipantsView: ->

    @createHeaderViews()

    super

    channel = @getData()

    isMyChannel = KD.isMyChannel channel

    @newParticipantButton.destroy()  unless isMyChannel


  createHeaderViews: ->

    channel = @getData()

    header = new KDCustomHTMLView
      tagName  : 'header'
      cssClass : 'general-header'

    header.addSubView @title = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'workspace-name'
      partial  : 'My Workspace'

    header.addSubView @chevron = @createMenu()

    header.addSubView @link = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'session-link'
      partial    : link = KD.utils.groupifyLink "IDE/#{channel.id}", yes
      attributes : href : link

    @addSubView header


  createMenu: ->

    channel = @getData()

    chevron = new KDButtonViewWithMenu
      title          : ''
      cssClass       : 'pm-title-chevron'
      itemChildClass : ActivityItemMenuItem
      delegate       : this
      menu           : @bound 'settingsMenu'
      style          : 'resurrection'
      callback       : (event) -> @contextMenu event


  settingsMenu: ->

    'Search'   : { callback: noop }
    'Settings' : { callback: @getDelegate().bound 'showSettingsPane' }
    'Minimize' : { callback: noop }


  createInputWidget: ->

    channel = @getData()
    @input  = new ReplyInputWidget {channel, collaboration : yes, cssClass : 'private'}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  participantAdded: (participant) ->

    appManager = KD.getSingleton 'appManager'
    appManager.tell 'IDE', 'setMachineUser', participant
