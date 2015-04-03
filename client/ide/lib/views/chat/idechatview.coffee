kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
KDTabView = kd.TabView
KDView = kd.View
CustomLinkView = require 'app/customlinkview'
IDEChatMessagePane = require './idechatmessagepane'
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

    @on 'ParticipantSelected', @bound 'handleParticipantSelected'


  handleParticipantSelected: (participant) ->

    socialHelpers.fetchAccount participant, (err, account) =>
      return console.error err  if err
      { nickname } = account.profile
      kd.singletons.appManager.tell 'IDE', 'switchToUserVideo', nickname


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


  handleVideoActive: ->

    @setClass 'is-videoActive'
    @chatVideoView.show()
    @chatPane.handleVideoActive()


  handleVideoEnded: ->

    @chatPane.handleVideoEnded()
    @chatVideoView.hide()
    @unsetClass 'is-videoActive'


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
