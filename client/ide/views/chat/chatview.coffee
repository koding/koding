ChatMessagePane  = require './chatmessagepane'
ChatSettingsPane = require './chatsettingspane'


class ChatView extends KDTabView

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
        KD.utils.stopDOMEvent event
        @end()

    @createLoader()

    KD.singletons.appManager.require 'Activity', @bound 'createPanes'

    @once 'CollaborationStarted',        @bound 'removeLoader'
    @once 'CollaborationNotInitialized', @bound 'removeLoader'
    @once 'CollaborationEnded',          @bound 'destroy'


  start: ->

    @visible = yes

    @show()


  end: ->

    @visible = no

    @hide()


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


  createPanes: ->

    channel         = @getData()
    type            = channel.typeConstant
    channelId       = channel.id
    name            = 'collaboration'
    chatOptions     = { name, type, channelId, @isInSession }
    settingsOptions = { @rtm, @isInSession }

    @addPane @chatPane     = new ChatMessagePane  chatOptions, channel
    @addPane @settingsPane = new ChatSettingsPane settingsOptions, channel

    @settingsPane.forwardEvents this, [
      'CollaborationStarted', 'CollaborationEnded', 'CollaborationNotInitialized'
      'ParticipantJoined', 'ParticipantLeft'
    ]

    @settingsPane.on 'SessionStarted', @bound 'sessionStarted'
    @settingsPane.on 'AddNewParticipantRequested', =>
      @showChatPane()

      KD.utils.wait 500, =>
        @chatPane.showAutoCompleteInput()

    @emit 'ready'


  showChatPane: ->

    @unsetClass 'onboarding'
    @showPane @chatPane


  showSettingsPane: -> @showPane @settingsPane


  sessionStarted: ->

    @showChatPane()
    @chatPane.refresh()


module.exports = ChatView
