class IDE.ChatSettingsPane extends KDTabPaneView

  JView.mixin @constructor

  constructor: (options = {}, data)->

    options.cssClass = 'chat-settings'

    super options, data

    @participantViews    = {}
    {@rtm, @isInSession} = options

    @createElements()

    @on 'CollaborationNotInitialized', => @everyone.destroySubViews()
    @on 'ParticipantJoined', @bound 'addParticipant'
    @on 'ParticipantLeft',   @bound 'removeParticipant'

    @on 'CollaborationEnded', =>
      @toggleButtons 'ended'
      @everyone.destroySubViews()

    @on 'CollaborationStarted', =>
      @toggleButtons 'started'

    @bindChannelEvents()


  bindChannelEvents: ->

    channel = @getData()

    channel
      .on 'RemovedFromChannel', (acc) => @removeParticipant acc.profile.nickname, yes
      .on 'AddedToChannel',     (acc) =>
        if @rtm.isReady
          @addParticipant acc.profile.nickname


  createElements: ->

    channel = @getData()

    @startSession = new KDButtonView
      title    : 'START SESSION'
      cssClass : 'solid green'
      callback : @bound 'initiateSession'

    buttonTitle = if @isInSession then 'LEAVE SESSION' else 'END SESSION'

    @endSession = new KDButtonView
      title    : buttonTitle
      disabled : yes
      cssClass : 'solid red hidden'
      callback : => if @isInSession then @leaveSession() else @stopSession()

    @back = new CustomLinkView
      title    : 'Chat'
      cssClass : 'chat-link'
      click    : => @getDelegate().showChatPane()

    @defaultSetting = new KDSelectBox
      defaultValue  : 'edit'
      selectOptions : [
        { title : 'CAN READ', value : 'read'}
        { title : 'CAN EDIT', value : 'edit'}
      ]

    @everyone  = new KDCustomHTMLView
      tagName  : 'ul'
      cssClass : 'settings everyone loading'

    @everyone.addSubView new KDLoaderView
      showLoader : yes
      size       :
        width    : 24

    @everyone.addSubView new KDCustomHTMLView
      cssClass : 'label'
      partial  : 'Fetching participants'


  initiateSession: ->

    @startSession.disable()
    {appManager} = KD.singletons

    appManager.tell 'IDE', 'startCollaborationSession', (err, channel) =>

      return @startSession.enable()  if err

      @toggleButtons 'started'
      @emit 'SessionStarted'


  leaveSession: ->

    KD.singletons.appManager.tell 'IDE', 'handleParticipantLeaveAction', KD.whoami()


  stopSession: ->

    {appManager} = KD.singletons

    appManager.tell 'IDE', 'stopCollaborationSession', (err, channel) =>

      return @endSession.enable()  if err

      @toggleButtons 'ended'


  toggleButtons: (state) ->

    startButton = @startSession
    endButton   = @endSession

    if state is 'started'
      endButton.show()
      endButton.enable()
      startButton.hide()
      startButton.disable()
    else
      startButton.show()
      startButton.enable()
      endButton.hide()
      endButton.disable()


  createParticipantsList: (accounts) ->

    @everyone.unsetClass 'loading'
    @everyone.destroySubViews()

    myNickname        = KD.nick()
    onlineUsers       = @rtm.getFromModel('participants').asArray()
    onlineNicknames   = (user.nickname for user in onlineUsers)

    for account in accounts
      {nickname} = account.profile
      isOnline   = onlineNicknames.indexOf(nickname) > -1

      if nickname isnt myNickname
        @createParticipantView account, isOnline


  createParticipantView: (account, isOnline) =>

    channel = @getData()
    view = new IDE.ChatParticipantView { isOnline, @isInSession }, { account, channel }
    @participantViews[account.profile.nickname] = view
    @everyone.addSubView view, null, isOnline


  removeParticipant: (username, unshare) ->

    @participantViews[username]?.destroy()
    delete @participantViews[username]

    if unshare and not @isInSession # not @isInSession means user is host, bad naming!
      @emit 'ParticipantKicked', username


  addParticipant: (nickname) ->

    participantView = @participantViews[nickname]

    return participantView.setAsOnline()  if participantView

    KD.remote.cacheable nickname, (err, account) =>
      @createParticipantView account.first, yes


  viewAppended: JView::viewAppended

  setTemplate: JView::setTemplate


  pistachio: ->

    return """
      <header class='chat-settings'>
        {{> @back}}
      </header>
      <ul class='settings default'>
        <li><label>Anyone who joins</label>{{> @defaultSetting}}</li>
      </ul>
      {{> @everyone}}
      <div class="warning">
        <p>Please be advised</p>
        <span>When you start a session, you share your "Entire VM".</span>
      </div>
      <div class='buttons'>
        {{> @startSession}} {{> @endSession}}
      </div>
    """
