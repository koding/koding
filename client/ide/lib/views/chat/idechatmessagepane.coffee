$                    = require 'jquery'
kd                   = require 'kd'
KDButtonViewWithMenu = kd.ButtonViewWithMenu
KDCustomHTMLView     = kd.CustomHTMLView
groupifyLink         = require 'app/util/groupifyLink'
ActivityItemMenuItem = require 'activity/views/activityitemmenuitem'
ReplyInputWidget     = require 'activity/views/privatemessage/replyinputwidget'
PrivateMessagePane   = require 'activity/views/privatemessage/privatemessagepane'
isMyChannel          = require 'app/util/isMyChannel'
isMyPost             = require 'app/util/isMyPost'
envDataProvider      = require 'app/userenvironmentdataprovider'
isKoding             = require 'app/util/isKoding'

CollaborationChannelParticipantsModel = require 'activity/models/collaborationchannelparticipants'
IDEChatParticipantHeads               = require './idechatparticipantheads'
IDEChatParticipantSearchController    = require './idechatparticipantsearchcontroller'

module.exports = class IDEChatMessagePane extends PrivateMessagePane


  constructor: (options = {}, data)->

    options.cssClass               = 'privatemessage'
    options.type                   = 'privatemessage' # backwards compatibility ~Umut
    options.channelType            = 'collaboration'
    options.autoCompleteClass      = IDEChatParticipantSearchController
    options.participantsModelClass = CollaborationChannelParticipantsModel

    super options, data

    options.initialParticipantStatus = 'requestpending'

    @isInSession = options.isInSession

    isHost = not @isInSession

    @define 'visible', => @getDelegate().visible

    @on 'AddedParticipant', @bound 'participantAdded'

    @input.input.on 'focus', @lazyBound 'handleFocus', yes

    @once 'NewParticipantButtonClicked', @bound 'removeOnboarding'

    ideApp = envDataProvider.getIDEFromUId @getOption 'mountedMachineUId'
    ideApp.on 'UserReachedVideoLimit', =>
      @autoComplete?.hideDropdown()




  handleFocus: (isFocused, event) ->

    return  unless isFocused
    return  unless $.contains @getElement(), event.target
    return  unless @isPageAtBottom()

    @glance()


  glance: ->

    return  unless @visible
    return  unless kd.singletons.windowController.focused

    super

    { mainView } = kd.singletons
    channel      = @getData()

    mainView.glanceChannelWorkspace channel


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

    if channel.lastMessage.payload?
      { systemType } = channel.lastMessage.payload
      systemType   or= channel.lastMessage.payload['system-message']

    isAlreadyUsed   = systemType not in [ 'initiate', 'start' ]
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
    @participantHeads.emit 'ShowParticipantAutocomplete'


  createHeaderViews: ->

    title        = 'Session'
    channel      = @getData()
    {appManager} = kd.singletons

    header = new KDCustomHTMLView
      tagName  : 'header'
      cssClass : 'general-header'

    { frontApp } = kd.singletons.appManager
    title = if isKoding() then frontApp.workspaceData.name else frontApp.mountedMachine.label

    header.addSubView @title = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'workspace-name'
      partial    : title
      attributes : href : '#'

    header.addSubView @chevron = @createMenu()

    header.addSubView @link = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'session-link'
      partial    : link = groupifyLink "IDE/#{channel.id}", yes
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
      'Search'     : { cssClass : 'disabled', callback: kd.noop }
      'Minimize'   : { callback : @getDelegate().bound 'end' }
      'Learn More' : { separator: yes, callback : -> kd.utils.createExternalLink 'https://koding.com/docs/collaboration' }
      # 'Settings' : { callback : @getDelegate().bound 'showSettingsPane' }

    isHost = not @isInSession

    if isHost
    then menu['End Session']   = { callback : => @parent.settingsPane.stopSession() }
    else menu['Leave Session'] = { callback : => @parent.settingsPane.leaveSession() }

    return menu


  createInputWidget: ->

    channel = @getData()
    @input  = new ReplyInputWidget {channel, collaboration : yes, cssClass : 'private'}

    @input.input.setClass 'collab-chat-input'

    @input.on 'EditModeRequested', @bound 'editLastMessage'


  participantAdded: (participant) ->

    @removeOnboarding()

    ideApp = envDataProvider.getIDEFromUId @getOption 'mountedMachineUId'
    ideApp?.setMachineUser [participant.profile.nickname]


  refresh: ->

    return  if not @listController.getItemCount()

    @resetPadding()
    item.checkIfItsTooTall()  for item in @listController.getListItems()
    @scrollView.wrapper.emit 'MutationHappened'
    @scrollDown()


  removeOnboarding: ->

    @onboarding?.destroy()
    @onboarding = null


  editLastMessage: ->

    items = @listController.getListItems().slice(0).reverse()

    for item in items when isMyPost item.getData()
      item.showEditWidget()
      @scrollView.wrapper.scrollToSubView item, 500
      return
