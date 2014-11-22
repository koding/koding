class IDE.ChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view hidden'
    options.hideHandleContainer = yes

    super options, data

    @unsetClass 'kdscrollview'

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      icon     : {}
      click    : (event) =>
        KD.utils.stopDOMEvent event
        @hide()

    KD.singletons.appManager.require 'Activity', @bound 'createPanes'


  createPanes: ->

    channel   = @getData()
    type      = channel.typeConstant
    channelId = channel.id
    name      = 'collaboration'

    @addPane @chatPane     = new IDE.ChatMessagePane {name, type, channelId}, channel
    @addPane @settingsPane = new IDE.ChatSettingsPane {}, channel

    @on 'ReceivedClickElseWhere', @bound 'hide'

    @on 'CollaborationStarted', => @settingsPane.emit 'CollaborationStarted'
    @on 'CollaborationEnded',   => @settingsPane.emit 'CollaborationEnded'


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
