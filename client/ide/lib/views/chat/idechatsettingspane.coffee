kd                          = require 'kd'
KDButtonView                = kd.ButtonView
KDCustomHTMLView            = kd.CustomHTMLView
KDLoaderView                = kd.LoaderView
KDSelectBox                 = kd.SelectBox
KDTabPaneView               = kd.TabPaneView
remote                      = require('app/remote').getInstance()
whoami                      = require 'app/util/whoami'
nick                        = require 'app/util/nick'
JView                       = require 'app/jview'
CustomLinkView              = require 'app/customlinkview'
IDEChatParticipantView      = require './idechatparticipantview'
ButtonViewWithProgressBar   = require 'app/commonviews/buttonviewwithprogressbar'


module.exports          = class IDEChatSettingsPane extends KDTabPaneView

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

    @startSession = new ButtonViewWithProgressBar
      buttonOptions   :
        title         : 'START SESSION'
        cssClass      : 'solid green start-session'
        callback      : @bound 'initiateSession'
      progressOptions :
        title         : 'STARTING SESSION'
      loaderOptions   :
        size          : width : 20
        loaderOptions :
          color       : '#FFFFFF'
          shape       : 'spiral'
          density     : 30
          speed       : 1.5


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

    kd.utils.wait 500,  => @startSession.updateProgress 5
    kd.utils.wait 1500, => @startSession.updateProgress 20
    kd.utils.wait 2500, => @startSession.updateProgress 65
    kd.utils.wait 3250, => @startSession.updateProgress 75

    { appManager } = kd.singletons

    appManager.tell 'IDE', 'startCollaborationSession', (err, channel) =>

      if err
        @startSession.resetProgress()
        return

      @toggleButtons 'started'
      @emit 'SessionStarted'


  leaveSession: ->

    kd.singletons.appManager.tell 'IDE', 'handleParticipantLeaveAction', whoami()


  stopSession: ->

    {appManager} = kd.singletons

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
    else
      startButton.resetProgress()
      endButton.hide()
      endButton.disable()


  createParticipantsList: (accounts) ->

    @everyone.unsetClass 'loading'
    @everyone.destroySubViews()

    myNickname      = nick()
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
    watchList         = @rtm.getFromModel("#{nick()}WatchMap").keys()
    isWatching        = watchList.indexOf(nickname) > -1
    channel           = @getData()
    options           = { isOnline, @isInSession, isWatching }
    data              = { account, channel }
    participantView   = new IDEChatParticipantView options, data

    @participantViews[nickname] = participantView
    @everyone.addSubView participantView, null, isOnline
    @onboarding?.destroy()


  removeParticipant: (username, unshare) ->

    @participantViews[username]?.destroy()
    delete @participantViews[username]

    if unshare and @amIHost
      @emit 'ParticipantKicked', username


  addParticipant: (nickname) ->

    return no if nickname is nick()

    participantView = @participantViews[nickname]

    return participantView.setAsOnline()  if participantView

    remote.cacheable nickname, (err, account) =>
      @createParticipantView account.first, yes


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
      </div>
      <div class='buttons'>
        {{> @startSession}} {{> @endSession}}
      </div>
    """
