$                    = require 'jquery'
kd                   = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView     = kd.CustomHTMLView
groupifyLink         = require 'app/util/groupifyLink'
ActivityItemMenuItem = require 'activity/views/activityitemmenuitem'
ReplyInputWidget     = require 'activity/views/privatemessage/replyinputwidget'
PrivateMessagePane   = require 'activity/views/privatemessage/privatemessagepane'
isMyChannel          = require 'app/util/isMyChannel'
isVideoFeatureEnabled = require 'app/util/isVideoFeatureEnabled'

CollaborationChannelParticipantsModel = require 'activity/models/collaborationchannelparticipants'
IDEChatMessageParticipantAvatar = require './idechatmessageparticipantavatar'
IDEChatParticipantHeads = require './idechatparticipantheads'

module.exports = class IDEChatMessagePane extends PrivateMessagePane

  constructor: (options = {}, data)->

    options.cssClass = 'privatemessage'

    # this is backwards compatibility related. ~Umut
    options.type = 'privatemessage'

    super options, data

    @isInSession = options.isInSession
    @videoActive = no

    @define 'visible', => @getDelegate().visible

    @on 'AddedParticipant', @bound 'participantAdded'

    @input.input.on 'focus', @lazyBound 'handleFocus', yes

    @once 'NewParticipantButtonClicked', @bound 'removeOnboarding'


  handleThresholdReached: ->

    return  unless @visible
    return  unless kd.singletons.windowController.focused

    @glance()


  handleFocus: (isFocused, event) ->

    return  unless isFocused
    return  unless $.contains @getElement(), event.target
    return  unless @isPageAtBottom()

    @glance()


  handleVideoActive: (participants) ->

    nicknames = Object.keys participants

    @participantHeads.setVideoListTitle()
    @participantsModel.setVideoState on, nicknames
    @videoActive = yes


  handleVideoEnded: ->

    @participantHeads.setDefaultListTitle()
    @participantsModel.setVideoState off
    @videoActive = no


  handleVideoParticipantsChanged: (payload) ->

    @participantsModel.applyVideoUpdate payload


  handleVideoParticipantConnected: (participant) ->

    @participantsModel.addVideoConnectedParticipant participant.nick


  handleVideoParticipantDisconnected: (participant) ->

    @participantsModel.removeVideoConnectedParticipant participant.nick


  handleVideoParticipantJoined: (participant) ->

    @participantsModel.addVideoActiveParticipant participant.nick


  handleVideoParticipantLeft: (participant) ->

    @participantsModel.removeVideoActiveParticipant participant.nick


  setActiveParticipantAvatar: (account) ->

    @participantsModel.addVideoActiveParticipant account.profile.nickname


  setSelectedParticipantAvatar: (account, isOnline) ->

    participant = account?.profile.nickname or null

    @participantsModel.setVideoSelectedParticipant participant, isOnline


  setAvatarTalkingState: (nickname, state) ->

    if state
    then @participantsModel.addTalkingParticipant nickname
    else @participantsModel.removeTalkingParticipant nickname


  glance: ->

    return  unless @visible
    return  unless kd.singletons.windowController.focused

    super

    { mainView } = kd.singletons
    channel      = @getData()

    mainView.glanceChannelWorkspace channel


  prepareParticipantsModel: ->

    @participantsModel = new CollaborationChannelParticipantsModel { channel: @getData() }


  createParticipantHeads: ->

    @participantHeads = new IDEChatParticipantHeads

    @forwardEvent @participantHeads, 'ParticipantSelected'


  createParticipantsView: ->

    @createHeaderViews()

    super

    if isMyChannel @getData()
    then @addOnboardingView()
    else @participantHeads.newParticipantButton.destroy()


  addOnboardingView: ->

    channel = @getData()

    isAlreadyUsed   = channel.lastMessage.payload?['system-message'] not in [ 'initiate', 'start' ]
    hasParticipants = channel.participantCount > 1

    return  if hasParticipants or isAlreadyUsed

    @addSubView @onboarding = new KDCustomHTMLView
      cssClass : 'onboarding'
      click    : @bound 'handleOnboardingViewClick'
      partial  : """
        <div class="arrow"></div>
        <div class="balloon"></div>
        <p>Start your collaboration session by <a href="#">adding someone</a>.</p>
      """

    channel.once 'AddedToChannel', @bound 'removeOnboarding'


  handleOnboardingViewClick: (event) ->

    return  unless event.target.tagName is 'A'

    @removeOnboarding()
    @showAutoCompleteInput()


  createHeaderViews: ->

    channel      = @getData()
    {appManager} = kd.singletons

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
      partial    : link = groupifyLink "IDE/#{channel.id}", yes
      attributes : href : link

    @addSubView header


  requestStartVideo: -> @emit 'ChatVideoStartRequested'
  requestEndVideo: -> @emit 'ChatVideoEndRequested'


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
      'Search'     : { cssClass : 'disabled', callback: kd.noop }
      'Minimize'   : { callback : @getDelegate().bound 'end' }
      'Learn More' : { separator: yes, callback : -> kd.utils.createExternalLink 'http://learn.koding.com/collaboration' }
      # 'Settings' : { callback : @getDelegate().bound 'showSettingsPane' }

    isHost = not @isInSession

    if isVideoFeatureEnabled() and isHost
      seperator = yes
      if @videoActive
      then menu['End Video Chat'] = { seperator, callback: @bound 'requestEndVideo' }
      else menu['Start Video Chat']  = { seperator, callback: @bound 'requestStartVideo' }

    if isHost
    then menu['End Session']   = { callback : => @parent.settingsPane.stopSession() }
    else menu['Leave Session'] = { callback : => @parent.settingsPane.leaveSession() }

    return menu


  createInputWidget: ->

    channel = @getData()
    @input  = new ReplyInputWidget {channel, collaboration : yes, cssClass : 'private'}

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  participantAdded: (participant) ->

    @removeOnboarding()

    appManager = kd.getSingleton 'appManager'
    appManager.tell 'IDE', 'setMachineUser', [participant.profile.nickname]


  refresh: ->

    return  if not @listController.getItemCount()

    @resetPadding()
    item.checkIfItsTooTall()  for item in @listController.getListItems()
    @scrollView.wrapper.emit 'MutationHappened'
    @scrollDown()


  removeOnboarding: ->

    @onboarding?.destroy()
    @onboarding = null
