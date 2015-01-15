class ChatMessagePane extends PrivateMessagePane

  constructor: (options = {}, data)->

    options.cssClass = 'privatemessage'

    super options, data

    @isInSession = options.isInSession

    @define 'visible', => @getDelegate().visible

    @on 'AddedParticipant', @bound 'participantAdded'

    @input.input.on 'focus', @lazyBound 'handleFocus', yes


    @once 'NewParticipantButtonClicked', => @onboarding?.destroy()


  handleThresholdReached: ->

    return  unless @visible
    return  unless KD.singletons.windowController.focused

    @glance()


  handleFocus: (isFocused, event) ->

    return  unless isFocused
    return  unless $.contains @getElement(), event.target
    return  unless @isPageAtBottom()

    @glance()


  glance: ->

    return  unless @visible
    return  unless KD.singletons.windowController.focused

    super

    { mainView } = KD.singletons
    channel      = @getData()

    mainView.glanceChannelWorkspace channel


  createParticipantsView: ->

    @createHeaderViews()

    super

    channel = @getData()

    isMyChannel = KD.isMyChannel channel

    if isMyChannel

      isAlreadyUsed   = channel.lastMessage.payload?['system-message'] not in [ 'initiate', 'start' ]
      hasParticipants = channel.participantCount > 1

      return  if hasParticipants or isAlreadyUsed

      @addSubView @onboarding = new KDCustomHTMLView
        cssClass : 'onboarding'
        click    : @bound 'handleOnboardingViewClick'
        partial  : """
          <div class="arrow"></div>
          <div class="balloon"></div>
          <p>This is your chat session, go ahead and <a href="#">add a friend</a> here.</p>
        """

    else

      @newParticipantButton.destroy()


  handleOnboardingViewClick: (e) ->

    if e.target.tagName is 'A'

      @onboarding.destroy()
      @showAutoCompleteInput()


  createHeaderViews: ->

    channel      = @getData()
    {appManager} = KD.singletons

    header = new KDCustomHTMLView
      tagName  : 'header'
      cssClass : 'general-header'

    header.addSubView @title = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'workspace-name'
      partial    : 'My Workspace'
      attributes : href : '#'
      # click      : (event) =>
      #   KD.utils.stopDOMEvent event
      #   @getDelegate().showSettingsPane()

    appManager.tell 'IDE', 'getWorkspaceName', @title.bound 'updatePartial'

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
      style          : 'resurrection chat-dropdown'
      callback       : (event) -> @contextMenu event


  settingsMenu: ->

    menu =
      'Search'     : cssClass : 'disabled', callback: noop
      # 'Settings'   : callback : @getDelegate().bound 'showSettingsPane'
      'Minimize'   : callback : @getDelegate().bound 'end'
      'Learn More' : separator: yes, callback : -> KD.utils.createExternalLink 'http://learn.koding.com/collaboration'

    if @isInSession
    then menu['Leave Session'] = { callback : => @parent.settingsPane.leaveSession() }
    else menu['End Session']   = { callback : => @parent.settingsPane.stopSession() }

    return menu


  createInputWidget: ->

    channel = @getData()
    @input  = new ReplyInputWidget {channel, collaboration : yes, cssClass : 'private'}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  participantAdded: (participant) ->

    # forward this event to channel, so that
    # it can change in other views as well.
    # Kind of observable. ~Umut
    channel = @getData()
    channel.emit 'AddedToChannel', participant

    @onboarding?.destroy()

    appManager = KD.getSingleton 'appManager'
    appManager.tell 'IDE', 'setMachineUser', [participant]


  refresh: ->

    return  if not @listController.getItemCount()

    @resetPadding()
    item.checkIfItsTooTall()  for item in @listController.getListItems()
    @scrollView.wrapper.emit 'MutationHappened'
    @scrollDown()

module.exports = ChatMessagePane
