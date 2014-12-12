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


  webtermConnect:(mode = 'create')->

    options = @generateOptions()
    options.mode = mode

    remote = null

    kite = @getKite()
    kite.init()
    kite.webtermConnect(options).then (remote) =>

      return  unless remote?

      @setOption "session", remote.session
      @terminal.eventHandler = (data)=>
        @emit "WebTermEvent", data

      @terminal.server = remote
      @sessionId = remote.session

      @emit "WebTermConnected", remote
      @_triedToReconnect = no

    .catch (err) =>

      KD.utils.warnAndLog "terminal: webtermConnect error",
        { hostnameAlias: @getMachine().getName(), reason:err?.message, options }

      if err.code is "ErrInvalidSession"

        @emit 'TerminalCanceled',
          machineId : @getMachine().uid
          sessionId : @getOptions().session
          error     : err

        return

      else
        throw err

    kite.on 'close', =>

      if not kite.isDisconnected and not @_triedToReconnect
        @_triedToReconnect = yes
        @webtermConnect if remote? then 'resume' else 'create'


  connectToTerminal: ->

    @appStorage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'

    @appStorage.fetchStorage =>

      @appStorage.setValue 'font'      , 'ubuntu-mono' if not @appStorage.getValue('font')?
      @appStorage.setValue 'fontSize'  , 14 if not @appStorage.getValue('fontSize')?
      @appStorage.setValue 'theme'     , 'green-on-black' if not @appStorage.getValue('theme')?
      @appStorage.setValue 'visualBell', false if not @appStorage.getValue('visualBell')?
      @appStorage.setValue 'scrollback', 1000 if not @appStorage.getValue('scrollback')?
      @appStorage.setValue 'blinkingCursor', yes if not @appStorage.getValue('blinkingCursor')?
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

    @container.unsetClass font.value for font in __webtermSettings.fonts
    @container.unsetClass theme.value for theme in __webtermSettings.themes

    @container.setClass @appStorage.getValue('font')
    @container.setClass @appStorage.getValue('theme')

    @container.$().css
      fontSize: @appStorage.getValue('fontSize') + 'px'

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
