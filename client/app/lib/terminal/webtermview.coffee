kd                   = require 'kd'
globals              = require 'globals'
KDCustomScrollView   = kd.CustomScrollView
KDNotificationView   = kd.NotificationView
KDButtonViewWithMenu = kd.ButtonViewWithMenu

settings             = require './settings'
Terminal             = require './terminal'
TerminalWrapper      = require './terminalwrapper'
WebTermMessagePane   = require './webtermmessagepane'
WebtermSettingsView  = require './webtermsettingsview'


module.exports = class WebTermView extends KDCustomScrollView

  constructor: (options = {}, data) ->

    options.cssClass     = kd.utils.curry 'webterm', options.cssClass
    options.wrapperClass = TerminalWrapper

    super options, data

    kd.getSingleton('mainView').on 'MainTabPaneShown', @bound 'mainTabPaneShown'


  viewAppended: ->

    super

    @container = @wrapper

    @container.setClass 'console ubuntu-mono green-on-black'

    @container.on 'scroll', -> @setScrollLeft 0

    { readOnly } = @getOptions()
    @terminal = new Terminal
      containerView : @container
      appView       : this
      readOnly      : readOnly ? no

    @options.advancedSettings ?= no

    if @options.advancedSettings

      @addSubView @advancedSettings = new KDButtonViewWithMenu
        style     : 'editor-advanced-settings-menu'
        icon      : yes
        iconOnly  : yes
        iconClass : 'cog'
        type      : 'contextmenu'
        delegate  : this
        itemClass : WebtermSettingsView
        click     : (pubInst, event) -> @contextMenu event
        menu      : @getAdvancedSettingsMenuItems.bind this


    @terminal.sessionEndedCallback = =>
      @emit 'WebTerm.terminated'  unless @_reconnectionInProgress

    @terminal.flushedCallback = =>
      @emit 'WebTerm.flushed'

    @terminal.on 'command', (param) =>
      @ringBell() if param is 'ring bell'

    @listenWindowResize()

    @on 'ReceivedClickElsewhere', =>
      @setFocus no
      kd.getSingleton('windowController').removeLayer this


    @getElement().addEventListener 'mousedown', (event) =>
      @terminal.mousedownHappened = yes
    , yes

    @forwardEvents @terminal, ['command', 'ScreenSizeChanged']

    @getDelegate().on 'KDTabPaneActive', => @terminal.updateSize yes

    # watch machine state:
    { computeController } = kd.singletons
    machineId             = @getMachine()._id

    computeController.on "public-#{machineId}", (event) =>
      if event.status in ['Stopping', 'Stopped']
        @terminal.cursor.stopBlink()

        # If machine is stopped we need to invalidate current sessions
        # user can decide to create a new one or destroy this one.
        if event.status is 'Stopped'
          @messagePane.handleError { message: 'ErrNoSession' }

    @setKeyView()

    @addSubView @messagePane = new WebTermMessagePane
      cssClass: 'hidden'

    @messagePane.on 'RequestNewSession', @lazyBound 'webtermConnect', 'create'
    @messagePane.on 'RequestReconnect', =>

      @_reconnectionInProgress = yes

      currentKite = @getKite()
      currentKite.off 'closed'

      @getMachine().invalidateKiteCache()

      kd.utils.defer @lazyBound 'webtermConnect', 'resume'

    @messagePane.on 'DiscardSession', @lazyBound 'emit', 'WebTerm.terminated'


  generateOptions: ->

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


  webtermConnect: (mode) ->

    mode ?= if @_lastRemote? then 'resume' else 'create'

    @messagePane.busy()

    options = @generateOptions()
    options.mode = mode

    @_lastRemote = null

    kite = @getKite()

    kite.init().then =>

      kite.webtermConnect(options).then (remote) =>

        return  unless remote?

        @_lastRemote = remote

        @setOption 'session', remote.session

        @terminal.eventHandler = (data) =>
          @emit 'WebTermEvent', data

        @terminal.server = remote
        @sessionId = remote.session

        @emit 'WebTermConnected', remote

        @_triedToReconnect = no

        kd.utils.wait 500, =>
          @messagePane.hide()
          @_reconnectionInProgress = no

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        @messagePane.handleError err


      kite.on 'close', =>

        if not kite.isDisconnected and not @_triedToReconnect
          @_triedToReconnect = yes

          # KodingKontrol and KodingKite handles reconnect on close
          # if we don't wait here we are causing a race condition with
          # some connection states, to prevent that we're waiting here
          # enough before re-trying to open same session. ~ GG
          @messagePane.busy()
          kd.utils.wait 3000, @bound 'webtermConnect'


  connectToTerminal: ->

    @appStorage = kd.getSingleton('appStorageController').storage 'Terminal', '1.0.1'

    @appStorage.fetchStorage =>

      @appStorage.setDefaults
        'font'           : 'ubuntu-mono'
        'fontSize'       : 14
        'theme'          : 'green-on-black'
        'visualBell'     : no
        'scrollback'     : 1000
        'blinkingCursor' : no
        'dimIfInactive'  : no

      @updateSettings()

      { mode } = @getOptions()
      @webtermConnect mode


  destroy: ->
    super

    kd.utils.killRepeat @checker

    unless @status is 'fail'
      @emit 'TerminalClosed',
        machineId : @getMachine().uid
        sessionId : @getOptions().session

    # This "suspend" is a variable that comes from IDEAppController's suspendTerminal method.
    # It is undefined in general.
    @terminal.server?.terminate()  unless @suspend


  updateSettings: ->

    for font in settings.fonts
      @container.unsetClass font.value
      @messagePane.unsetClass font.value

    for theme in settings.themes
      @container.unsetClass theme.value
      @container.unsetClass 'is-dimmed'
      @messagePane.unsetClass theme.value
      @messagePane.unsetClass 'is-dimmed'

    font        = @appStorage.getValue 'font'
    theme       = @appStorage.getValue 'theme'
    dimFlag     = if @appStorage.getValue('dimIfInactive') then 'is-dimmed' else ''
    themeBucket = [font, theme, dimFlag].join ' '

    @container.setClass themeBucket
    @messagePane.setClass themeBucket

    @container.setStyle
      fontSize: @appStorage.getValue('fontSize') + 'px'

    @updateColor()

    @terminal.updateSize true
    @terminal.scrollToBottom()
    @terminal.controlCodeReader.visualBell = @appStorage.getValue 'visualBell'
    @terminal.setScrollbackLimit @appStorage.getValue 'scrollback'
    @terminal.cursor.setBlinking @appStorage.getValue 'blinkingCursor'


  updateColor: ->

    @setStyle
      color: (global.getComputedStyle @container.getElement()).backgroundColor


  setKeyView: ->
    kd.getSingleton('windowController').addLayer this
    @setFocus()
    @emit 'KeyViewIsSet'
    @once 'ReceivedClickElsewhere', => @setFocus no

  setFocus: (state = yes) ->
    @focused = state
    @terminal.setFocused state
    @updateColor()

  click: ->
    @setKeyView()
    @restoreRange()

  dblClick: ->
    @restoreRange()

  restoreRange: ->
    range = kd.utils.getSelectionRange()
    return  unless range
    return  if range.startOffset is range.endOffset and range.startContainer is range.endContainer
    kd.utils.defer ->
      kd.utils.addRange range

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

  listenFullscreen: (event) ->
    requestFullscreen = (event.metaKey or event.ctrlKey) and event.keyCode is 13
    if requestFullscreen
      mainView = kd.getSingleton 'mainView'
      mainView.toggleFullscreen()
      event.preventDefault()

  triggerFitToWindow: ->

    return  unless @terminal?.server?
    return  if @_reconnectionInProgress
    # bc a hidden terminal has 1 col and 1 row
    # we assume that the terminal is hidden and do not trigger resize
    # maybe, better would be to check if the dom element is in the body - SY
    return  if @terminal.sizeX + @terminal.sizeY <= 2

    @terminal.server.controlSequence String.fromCharCode 2
    @terminal.server.input 'F'

  mainTabPaneShown: (pane) ->

    return  unless pane.hasClass('ide') and pane.getElement().contains @getElement()

    el = @container.getElement()
    el.scrollTop = el.scrollHeight


  ringBell: do (bell = try new Audio '/a/audio/bell.wav') -> (event) ->
    event?.preventDefault()

    if not bell? or @terminal.controlCodeReader.visualBell
    then new KDNotificationView { title: 'Bell!', duration: 100 }
    else bell.play()
