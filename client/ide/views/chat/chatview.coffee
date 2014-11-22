class IDE.ChatView extends KDTabView

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view hidden'
    options.hideHandleContainer = yes

    super options, data

    channel = @getData()

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      icon     : {}
      click    : (event) =>
        KD.utils.stopDOMEvent event
        @hide()

    @addPane @chatPane     = new IDE.ChatMessagePane {}, channel
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
