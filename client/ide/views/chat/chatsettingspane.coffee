ChatParticipantView = require './chatparticipantview'


class ChatSettingsPane extends KDTabPaneView

  JView.mixin @constructor

  constructor: (options = {}, data)->

    options.cssClass = 'chat-settings'

    super options, data

    @participantViews    = {}
    {@rtm, @isInSession} = options

    @amIHost = not @isInSession # not @isInSession means user is host, bad naming!

    @createElements()

    @on 'CollaborationNotInitialized', => @everyone.destroySubViews()
    @on 'ParticipantJoined', @bound 'addParticipant'
    @on 'ParticipantLeft',   @bound 'removeParticipant'
    @on 'PermissionChanged', @bound 'handlePermissionChange'

    @on 'CollaborationEnded', =>
      @toggleButtons 'ended'
      @everyone.destroySubViews()

    @on 'CollaborationStarted', =>
      @toggleButtons 'started'

    @bindChannelEvents()


  bindChannelEvents: ->

    return

    channel = @getData()

    channel
      .on 'RemovedFromChannel', (acc) => @removeParticipant acc.profile.nickname, yes
      .on 'AddedToChannel',     (acc) =>

        return  unless acc.profile?
        return  unless @rtm.isReady

        @addParticipant acc.profile.nickname


  createElements: ->

    channel = @getData()

    @startSession = new KDButtonView
      title    : 'START SESSION'
      cssClass : 'solid green'
      loader   : yes
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

    @defaultPermission = new KDSelectBox
      defaultValue  : 'edit'
      callback      : (value) => @setDefaultPermission value
      disabled      : not @amIHost
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
    @startSession.showLoader()

    {appManager} = KD.singletons

    appManager.tell 'IDE', 'startCollaborationSession', (err, channel) =>

      return @startSession.enable()  if err

      @toggleButtons 'started'
      @startSession.hideLoader()
      @emit 'SessionStarted'


  leaveSession: ->

    KD.singletons.appManager.tell 'IDE', 'handleParticipantLeaveAction', KD.whoami()


  stopSession: ->

    {appManager} = KD.singletons

    appManager.tell 'IDE', 'showEndCollaborationModal', (err, channel) =>

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

    myNickname      = KD.nick()
    onlineUsers     = @rtm.getFromModel('participants').asArray()
    onlineNicknames = (user.nickname for user in onlineUsers)

    for account in accounts
      {nickname} = account.profile
      isOnline   = onlineNicknames.indexOf(nickname) > -1

      if nickname isnt myNickname
        @createParticipantView account, isOnline

    if accounts.length is 1 and @amIHost

      @everyone.addSubView @onboarding = new KDCustomHTMLView
        tagName : 'p'
        click   : @bound 'handleOnboardingViewClick'
        partial : """
          There is no collaborator in your session. <a href="#">Click here</a> to invite someone to this session.
        """


  handleOnboardingViewClick: (e) ->

    if e.target.tagName is 'A'

      @onboarding.destroy()
      @emit 'AddNewParticipantRequested'


  createParticipantView: (account, isOnline) =>

    {nickname}        = account.profile
    watchList         = @rtm.getFromModel("#{KD.nick()}WatchMap").keys()
    isWatching        = watchList.indexOf(nickname) > -1
    permissionsMap    = @rtm.getFromModel 'permissions'
    defaultPermission = permissionsMap.get 'default'
    permission        = permissionsMap.get(nickname) or defaultPermission
    channel           = @getData()
    options           = { isOnline, @isInSession, isWatching, permission }
    data              = { account, channel }
    participantView   = new ChatParticipantView options, data

    @participantViews[nickname] = participantView
    @everyone.addSubView participantView, null, isOnline
    @onboarding?.destroy()

    participantView.on 'ParticipantPermissionChanged', (permission) =>
      @rtm.getFromModel('permissions').set nickname, permission


  removeParticipant: (username, unshare) ->

    @participantViews[username]?.destroy()
    delete @participantViews[username]

    if unshare and @amIHost
      @emit 'ParticipantKicked', username


  addParticipant: (nickname) ->

    participantView = @participantViews[nickname]

    return participantView.setAsOnline()  if participantView

    KD.remote.cacheable nickname, (err, account) =>
      @createParticipantView account.first, yes


  updateDefaultPermissions: ->

    permissions = @rtm.getFromModel 'permissions'
    @defaultPermission.setValue permissions.get 'default'


  setDefaultPermission: (value) ->

    @rtm.getFromModel('permissions').set 'default', value


  handlePermissionChange: (event) ->

    {newValue, property} = event

    return  unless newValue in ['edit', 'read']

    if property is 'default'
      @defaultPermission.setValue newValue
    else
      @participantViews[property]?.permissions.setValue newValue


  viewAppended: JView::viewAppended

  setTemplate: JView::setTemplate


  pistachio: ->

    return """
      <header class='chat-settings'>
        {{> @back}}
      </header>
      <ul class='settings default'>
        <li><label>Anyone who joins</label>{{> @defaultPermission}}</li>
      </ul>
      {{> @everyone}}
      <div class="warning">
        <span>Have sessions with people <strong>you trust</strong>, they can view and edit <strong>all your files</strong>.</span>
        <p><a href="http://learn.koding.com/collaboration#experimental" target="_blank">- Experimental Feature -</a></p>
      </div>
      <div class='buttons'>
        {{> @startSession}} {{> @endSession}}
      </div>
    """


module.exports = ChatSettingsPane
