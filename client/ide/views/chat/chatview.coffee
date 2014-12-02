class IDE.ChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view loading'
    options.hideHandleContainer = yes

    super options, data

    @visible = no

    {@rtm, @isInSession} = options

    @unsetClass 'kdscrollview'

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      icon     : {}
      click    : (event) =>
        KD.utils.stopDOMEvent event
        @end()

    @createLoader()

    KD.singletons.appManager.require 'Activity', @bound 'createPanes'

    @once 'CollaborationStarted',        @bound 'removeLoader'
    @once 'CollaborationNotInitialized', @bound 'removeLoader'


  start: ->

    @visible = yes

    @show()


  end: ->

    @visible = no

    @hide()


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

    channel   = @getData()
    type      = channel.typeConstant
    channelId = channel.id
    name      = 'collaboration'

    @addPane @chatPane     = new IDE.ChatMessagePane {name, type, channelId}, channel
    @addPane @settingsPane = new IDE.ChatSettingsPane { @rtm, @isInSession }, channel

    @settingsPane.forwardEvents this, [
      'CollaborationStarted', 'CollaborationEnded', 'CollaborationNotInitialized'
      'ParticipantJoined', 'ParticipantLeft'
    ]

    @settingsPane.on 'SessionStarted', @bound 'showChatPane'

    @emit 'ready'


  showChatPane: -> @showPane @chatPane


  showSettingsPane: -> @showPane @settingsPane

