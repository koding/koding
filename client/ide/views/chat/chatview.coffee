class IDE.ChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view loading'
    options.hideHandleContainer = yes

    super options, data

    @rtm = options.rtm

    @unsetClass 'kdscrollview'

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      icon     : {}
      click    : (event) =>
        KD.utils.stopDOMEvent event
        @hide()

    @createLoader()

    KD.singletons.appManager.require 'Activity', @bound 'createPanes'

    @once 'CollaborationStarted',        @bound 'removeLoader'
    @once 'CollaborationNotInitialized', @bound 'removeLoader'


  createLoader: ->

    @loaderView = new KDView cssClass: 'loader-view'

    @loaderView.addSubView new KDLoaderView
      showLoader : yes
      size       :
        width    : 24

    @loaderView.addSubView new KDCustomHTMLView
      cssClass : 'label'
      partial  : 'Preparing collaboration...'

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
    @addPane @settingsPane = new IDE.ChatSettingsPane { @rtm }, channel

    @on 'ReceivedClickElseWhere', @bound 'hide'

    @settingsPane.forwardEvents this, [
      'CollaborationStarted', 'CollaborationEnded', 'CollaborationNotInitialized'
      'ParticipantJoined', 'ParticipantLeft'
    ]


  showChatPane: -> @showPane @chatPane

  showSettingsPane: -> @showPane @settingsPane


  show: ->

    {windowController} = KD.singletons
    windowController.addLayer this

    super

  hide: ->

    log 'being hidden'

    super


  # click: -> @showPane if @getActivePane() is @settingsPane then @chatPane else @settingsPane
