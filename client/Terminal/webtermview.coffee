class WebTermView extends KDCustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass     = KD.utils.curry 'webterm', options.cssClass
    options.wrapperClass = TerminalWrapper

    super options, data

    KD.getSingleton('mainView').on 'MainTabPaneShown', @bound 'mainTabPaneShown'


  viewAppended: ->

    super

    @container = @wrapper

    @container.setClass 'console ubuntu-mono green-on-black'

    @container.on 'scroll', -> @setScrollLeft 0

    { readOnly } = @getOptions()
    @terminal = new WebTerm.Terminal
      containerView : @container
      appView       : this
      readOnly      : readOnly ? no

    @options.advancedSettings ?= no

    if @options.advancedSettings

      @addSubView @advancedSettings = new KDButtonViewWithMenu
        style     : 'editor-advanced-settings-menu'
        icon      : yes
        iconOnly  : yes
        iconClass : "cog"
        type      : "contextmenu"
        delegate  : this
        itemClass : WebtermSettingsView
        click     : (pubInst, event)-> @contextMenu event
        menu      : @getAdvancedSettingsMenuItems.bind this


    @terminal.sessionEndedCallback = (sessions) =>
      @emit "WebTerm.terminated"

    @terminal.flushedCallback = =>
      @emit 'WebTerm.flushed'

    @listenWindowResize()

    @on "ReceivedClickElsewhere", =>
      @setFocus no
      KD.getSingleton('windowController').removeLayer this


    @getElement().addEventListener "mousedown", (event) =>
      @terminal.mousedownHappened = yes
    , yes

    @forwardEvent @terminal, 'command'

    KD.mixpanel "Open Webterm, click", {
      machineName : @getMachine().getName()
    }

    @getDelegate().on 'KDTabPaneActive', => @terminal.updateSize yes

    # watch machine state:
    { computeController } = KD.singletons
    computeController.on "public-#{@getMachine()._id}", (event) =>
      if event.status in [Machine.State.Stopping, Machine.State.Stopped]
        @terminal.cursor.stopBlink()

    @setKeyView()

    @addSubView @messagePane = new WebTermMessagePane
      cssClass: 'hidden'

    @messagePane.on 'RequestNewSession', @lazyBound 'webtermConnect', 'create'
    @messagePane.on 'RequestReconnect',  @bound 'webtermConnect'


  generateOptions:->

    delegateOptions = @getDelegate().getOptions()
    myOptions       = @getOptions()

    params =
      remote      : @terminal.clientInterface
      sizeX       : @terminal.sizeX
      sizeY       : @terminal.sizeY
      joinUser    : myOptions.joinUser  ? delegateOptions.joinUser
      session     : @sessionId ? myOptions.session ? delegateOptions.session
      mode        : myOptions.mode ? 'create'

    return params


  getMachine: -> @getOption 'machine'


  getKite: -> @getMachine().getBaseKite()


  webtermConnect: (mode)->

    mode ?= if @_lastRemote? then 'resume' else 'create'

    @messagePane.busy()

    options = @generateOptions()
    options.mode = mode

    @_lastRemote = null

    kite = @getKite()

    kite.init()

    kite.webtermConnect(options).then (remote)=>

      return  unless remote?

      @_lastRemote = remote

      @setOption "session", remote.session

      @terminal.eventHandler = (data)=>
        @emit "WebTermEvent", data

      @terminal.server = remote
      @sessionId = remote.session

      @emit "WebTermConnected", remote

      @_triedToReconnect = no

      KD.utils.wait 500, @messagePane.bound 'hide'

    .timeout ComputeController.timeout

    .catch (err)=>

      throw err  unless @messagePane.handleError err


    kite.on 'close', =>

      if not kite.isDisconnected and not @_triedToReconnect
        @_triedToReconnect = yes
        @webtermConnect()


  connectToTerminal: ->

    @appStorage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'

    @appStorage.fetchStorage =>

      @appStorage.setDefaults
        'font'           : 'ubuntu-mono'
        'fontSize'       : 14
        'theme'          : 'green-on-black'
        'visualBell'     : no
        'scrollback'     : 1000
        'blinkingCursor' : no

      @updateSettings()

      {mode} = @getOptions()
      @webtermConnect mode


  destroy: ->
    super

    KD.utils.killRepeat @checker

    unless @status is "fail"
      @emit "TerminalClosed",
        machineId : @getMachine().uid
        sessionId : @getOptions().session

    @terminal.server?.terminate()


  updateSettings: ->

    for font in __webtermSettings.fonts
      @container.unsetClass font.value
      @messagePane.unsetClass font.value

    for theme in __webtermSettings.themes
      @container.unsetClass theme.value
      @messagePane.unsetClass theme.value

    font        = @appStorage.getValue 'font'
    theme       = @appStorage.getValue 'theme'
    themeBucket = [font, theme].join ' '

    @container.setClass themeBucket
    @messagePane.setClass themeBucket

    @container.$().css
      fontSize: @appStorage.getValue('fontSize') + 'px'

    @$().css
      color: (window.getComputedStyle @container.getElement()).backgroundColor

    @terminal.updateSize true
    @terminal.scrollToBottom()
    @terminal.controlCodeReader.visualBell = @appStorage.getValue 'visualBell'
    @terminal.setScrollbackLimit @appStorage.getValue 'scrollback'
    @terminal.cursor.setBlinking @appStorage.getValue 'blinkingCursor'

  setKeyView: ->
    KD.getSingleton('windowController').addLayer this
    @setFocus()
    @emit 'KeyViewIsSet'
    @once "ReceivedClickElsewhere", => @setFocus no

  setFocus: (state = yes) ->
    @focused = state
    @terminal.setFocused state

  click: ->
    @setKeyView()
    @restoreRange()

  dblClick: ->
    @restoreRange()

  restoreRange: ->
    range = @utils.getSelectionRange()
    return  unless range
    return  if range.startOffset is range.endOffset and range.startContainer is range.endContainer
    @utils.defer =>
      @utils.addRange range

  keyDown: (event) ->
    @listenFullscreen event
    @terminal.keyDown event

  keyPress: (event) ->
    @terminal.keyPress event

  keyUp: (event) ->
    @terminal.keyUp event

  _windowDidResize: (event) -> @terminal.windowDidResize()

  getAdvancedSettingsMenuItems: ->
    settings     :
      type       : 'customView'
      view       : new WebtermSettingsView
        delegate : this

  listenFullscreen: (event)->
    requestFullscreen = (event.metaKey or event.ctrlKey) and event.keyCode is 13
    if requestFullscreen
      mainView = KD.getSingleton "mainView"
      mainView.toggleFullscreen()
      event.preventDefault()


  mainTabPaneShown: (pane) ->

    return  unless pane.hasClass('ide') and pane.getElement().contains @getElement()

    el = @container.getElement()
    el.scrollTop = el.scrollHeight
