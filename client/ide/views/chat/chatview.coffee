class IDE.ChatView extends KDTabView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.cssClass            = 'chat-view loading'
    options.hideHandleContainer = yes

    super options, data

    {@rtm, @isInSession} = options

    @unsetClass 'kdscrollview'

    @addSubView new CustomLinkView
      title    : ''
      cssClass : 'close'
      icon     : {}
      click    : (event) =>
        KD.utils.stopDOMEvent event
        @hide()

    @createElements()
    @createLoader()

    KD.singletons.appManager.require 'Activity', @bound 'createPanes'

    @once 'CollaborationStarted',        @bound 'removeLoader'
    @once 'CollaborationNotInitialized', @bound 'removeLoader'


  createElements: ->

    channel = @getData()

    header = new KDCustomHTMLView
      tagName  : 'header'
      cssClass : 'general-header'

    header.addSubView @title = new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'workspace-name'
      partial  : 'My Workspace'

    header.addSubView @chevron = @createMenu()

    header.addSubView @link = new KDCustomHTMLView
      tagName    : 'a'
      cssClass   : 'session-link'
      partial    : link = KD.utils.groupifyLink "IDE/#{channel.id}", yes
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
      style          : 'resurrection'
      callback       : (event) -> @contextMenu event


  settingsMenu: ->

    'Search'   : { callback: noop }
    'Settings' : { callback: @bound 'showSettingsPane' }
    'Minimize' : { callback: noop }


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

    @emit 'ready'


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
