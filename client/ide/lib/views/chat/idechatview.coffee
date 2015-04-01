kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
KDTabView = kd.TabView
KDView = kd.View
CustomLinkView = require 'app/customlinkview'
IDEChatMessagePane = require './idechatmessagepane'
IDEChatSettingsPane = require './idechatsettingspane'
IDEChatVideoView    = require './idechatvideoview'

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


  createChatVideoView: ->

    @chatVideoView = new IDEChatVideoView { cssClass: 'hidden' }
    @addSubView @chatVideoView


  createPanes: ->

    channel         = @getData()
    type            = channel.typeConstant
    channelId       = channel.id
    name            = 'collaboration'
    chatOptions     = { name, type, channelId, @isInSession }
    settingsOptions = { @rtm, @isInSession }

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

    @emit 'ready'


  showChatPane: ->

    @unsetClass 'onboarding'
    @showPane @chatPane


  showSettingsPane: -> @showPane @settingsPane


  sessionStarted: ->

    @showChatPane()
    @chatPane.refresh()
