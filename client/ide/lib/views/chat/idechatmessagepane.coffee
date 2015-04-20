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

    @once 'NewParticipantButtonClicked', => @onboarding?.destroy()


  handleThresholdReached: ->

    return  unless @visible
    return  unless kd.singletons.windowController.focused

    @glance()


  handleFocus: (isFocused, event) ->

    return  unless isFocused
    return  unless $.contains @getElement(), event.target
    return  unless @isPageAtBottom()

    @glance()


  handleVideoActive: -> @videoActive = yes
  handleVideoEnded: -> @videoActive = no


  setActiveParticipantAvatar: (account) ->

    for own id, avatar of @participantMap
      if id is account._id
      then avatar.setClass 'is-activeParticipant'
      else avatar.unsetClass 'is-activeParticipant'


  setSelectedParticipantAvatar: (account) ->

    for own id, avatar of @participantMap
      # if account is null all avatars will receive `unsetClass` calls.
      # `null` account means: "SELECT NO ONE!"
      if id is account?._id
      then avatar.setClass 'is-selectedParticipant'
      else avatar.unsetClass 'is-selectedParticipant'


  setAvatarTalkingState: (nickname, state) ->

    for _, avatar of @participantMap when avatar.data.profile.nickname is nickname
      if state
      then avatar.setClass 'is-talkingParticipant'
      else avatar.unsetClass 'is-talkingParticipant'


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

    channel = @getData()

    isMyChannel_ = isMyChannel channel

    if isMyChannel_

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

    else

      @newParticipantButton.destroy()


  handleOnboardingViewClick: (e) ->

    if e.target.tagName is 'A'

      @onboarding.destroy()
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

    @onboarding?.destroy()

    appManager = kd.getSingleton 'appManager'
    appManager.tell 'IDE', 'setMachineUser', [participant.profile.nickname]


  addParticipant: (participant) ->

    return  unless participant
    return  if @participantMap[participant._id]?

    participant.id = participant._id

    @heads.addSubView avatar = new IDEChatMessageParticipantAvatar
      size      :
        width   : 25
        height  : 25
      origin    : participant

    @forwardEvent avatar, 'ParticipantSelected'

    @participantMap[participant._id] = avatar


  setHeadsPosition: ->

    floors = Math.floor (Object.keys(@participantMap).length + 1) / 8
    @heads.$().css marginTop : "#{-(floors * 35)}px"


  refresh: ->

    return  if not @listController.getItemCount()

    @resetPadding()
    item.checkIfItsTooTall()  for item in @listController.getListItems()
    @scrollView.wrapper.emit 'MutationHappened'
    @scrollDown()
