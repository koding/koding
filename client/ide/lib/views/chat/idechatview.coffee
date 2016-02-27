kd                  = require 'kd'
KDView              = kd.View
KDTabView           = kd.TabView
KDLoaderView        = kd.LoaderView
KDCustomHTMLView    = kd.CustomHTMLView

CustomLinkView      = require 'app/customlinkview'
IDEChatMessagePane  = require './idechatmessagepane'
IDEChatSettingsPane = require './idechatsettingspane'
envDataProvider     = require 'app/userenvironmentdataprovider'

socialHelpers = require '../../collaboration/helpers/social'

module.exports = class IDEChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view loading onboarding'
    options.hideHandleContainer = yes

    super options, data

    @visible = no

    { @rtm, @isInSession, @mountedMachineUId } = options

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


  start: ->

    @visible = yes
    @show()


  end: ->

    @visible = no
    @hide()
    @emit 'ViewBecameHidden'


  focus: -> @chatPane.focus()


  show: ->

    super

    @chatPane?.refresh()
    @emit 'ViewBecameVisible'


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


  createPanes: ->

    channel         = @getData()
    type            = channel.typeConstant
    channelId       = channel.id
    name            = 'collaboration'
    chatOptions     = { name, type, channelId, @isInSession, @mountedMachineUId }
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


  getIDEApp : -> envDataProvider.getIDEFromUId @mountedMachineUId


  showChatPane: ->

    @unsetClass 'onboarding'
    @showPane @chatPane


  showSettingsPane: -> @showPane @settingsPane


  sessionStarted: ->

    @showChatPane()
    @chatPane.refresh()
