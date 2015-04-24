kd                  = require 'kd'
KDCustomHTMLView    = kd.CustomHTMLView
KDLoaderView        = kd.LoaderView
KDTabView           = kd.TabView
KDView              = kd.View
CustomLinkView      = require 'app/customlinkview'
IDEChatMessagePane  = require './idechatmessagepane'
IDEChatSettingsPane = require './idechatsettingspane'
IDEChatVideoView    = require './idechatvideoview'

socialHelpers = require '../../collaboration/helpers/social'

module.exports = class IDEChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view loading onboarding'
    options.hideHandleContainer = yes

    super options, data

    @visible = no

    {@rtm, @isInSession} = options

    @unsetClass 'kdscrollview'

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      tooltip  :
        title  : 'Minimize'
      icon     : {}
      click    : (event) =>
        kd.utils.stopDOMEvent event
        @end()

    @createLoader()

    kd.singletons.appManager.require 'Activity', @bound 'createPanes'

    @once 'CollaborationStarted',        @bound 'removeLoader'
    @once 'CollaborationNotInitialized', @bound 'removeLoader'
    @once 'CollaborationEnded',          @bound 'destroy'

    @on 'VideoCollaborationActive', @bound 'handleVideoActive'
    @on 'VideoCollaborationEnded',  @bound 'handleVideoEnded'
    @on 'VideoActiveParticipantDidChange', @bound 'handleVideoActiveParticipantChanged'
    @on 'VideoSelectedParticipantDidChange', @bound 'handleVideoSelectedParticipantChanged'
    @on 'VideoParticipantTalkingStateDidChange', @bound 'handleVideoParticipantTalkingStateChanged'

    @on 'VideoParticipantDidConnect', @bound 'handleVideoParticipantConnected'
    @on 'VideoParticipantDidDisconnect', @bound 'handleVideoParticipantDisconnected'
    @on 'VideoParticipantDidJoin', @bound 'handleVideoParticipantJoined'
    @on 'VideoParticipantDidLeave', @bound 'handleVideoParticipantLeft'


  handleParticipantSelected: (account) ->

    { nickname } = account.profile
    kd.singletons.appManager.tell 'IDE', 'switchToUserVideo', nickname


  handleVideoActiveParticipantChanged: (nickname, account) ->

    @chatPane.setActiveParticipantAvatar account


  handleVideoSelectedParticipantChanged: (nickname, account, isOnline) ->

    @chatPane.setSelectedParticipantAvatar account, isOnline


  handleVideoParticipantTalkingStateChanged: (nickname, state) ->

    @chatPane.setAvatarTalkingState nickname, state


  handleVideoParticipantConnected: (participant) ->

    @chatPane.handleVideoParticipantConnected participant


  handleVideoParticipantDisconnected: (participant) ->

    @chatPane.handleVideoParticipantDisconnected participant


  handleVideoParticipantJoined: (participant) ->

    @chatPane.handleVideoParticipantJoined participant


  handleVideoParticipantLeft: (participant) ->

    @chatPane.handleVideoParticipantLeft participant


  start: ->

    @visible = yes
    @show()


  end: ->

    @visible = no
    @hide()


  focus: -> @chatPane.focus()


  show: ->

    super

    @chatPane?.refresh()


  createLoader: ->

    @loaderView = new KDView cssClass: 'loader-view'

    @loaderView.addSubView new KDLoaderView
      showLoader : yes
      size       :
        width    : 24

    @loaderView.addSubView new KDCustomHTMLView
      cssClass : 'label'
      partial  : 'Preparing collaboration'

    @addSubView @loaderView


  removeLoader: ->

    @loaderView.destroy()
    @unsetClass 'loading'


  setVideoActiveState: (state) ->

    if state
    then @setClass 'is-videoActive'
    else @unsetClass 'is-videoActive'

    kd.utils.defer @bound 'focus'


  handleVideoActive: ->

    {appManager} = kd.singletons
    appManager.tell 'IDE', 'fetchVideoParticipants', (participants) =>
      @setVideoActiveState on
      @chatVideoView.show()
      @chatPane.handleVideoActive participants


  handleVideoEnded: ->

    @setVideoActiveState off
    @chatPane.handleVideoEnded()
    @chatVideoView.hide()


  getVideoView: -> @chatVideoView


  createChatVideoView: ->

    @chatVideoView = new IDEChatVideoView { cssClass: 'hidden' }, @getData()
    @addSubView @chatVideoView


  createPanes: ->

    channel         = @getData()
    type            = channel.typeConstant
    channelId       = channel.id
    name            = 'collaboration'
    chatOptions     = { name, type, channelId, @isInSession }
    settingsOptions = { @rtm, @isInSession }

    @createChatVideoView()

    @addPane @chatPane     = new IDEChatMessagePane  chatOptions, channel
    @addPane @settingsPane = new IDEChatSettingsPane settingsOptions, channel

    @chatPane.on 'ParticipantSelected', @bound 'handleParticipantSelected'

    @settingsPane.forwardEvents this, [
      'CollaborationStarted', 'CollaborationEnded', 'CollaborationNotInitialized'
      'ParticipantJoined', 'ParticipantLeft'
    ]

    @settingsPane.on 'SessionStarted', @bound 'sessionStarted'
    @settingsPane.on 'AddNewParticipantRequested', =>
      @showChatPane()

      kd.utils.wait 500, =>
        @chatPane.showAutoCompleteInput()

    @bindVideoCollaborationEvents()

    @emit 'ready'


  bindVideoCollaborationEvents: ->

    {appManager} = kd.singletons

    @chatPane
      .on 'ChatVideoStartRequested', -> appManager.tell 'IDE', 'startVideoCollaboration'
      .on 'ChatVideoEndRequested', -> appManager.tell 'IDE', 'endVideoCollaboration'


  showChatPane: ->

    @unsetClass 'onboarding'
    @showPane @chatPane


  showSettingsPane: -> @showPane @settingsPane


  sessionStarted: ->

    @showChatPane()
    @chatPane.refresh()
