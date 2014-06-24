class WebTermView extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'webterm', options.cssClass

    super options, data

    @initBackoff()

  viewAppended: ->

    @container = new KDView
      cssClass : "console ubuntu-mono green-on-black"
      bind     : "scroll"

    @container.on "scroll", => @container.$().scrollLeft 0

    @addSubView @container

    { readOnly } = @getOptions()
    @terminal = new WebTerm.Terminal
      containerView : @container
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
      @clearBackoffTimeout()

    @terminal.flushedCallback = =>
      @emit 'WebTerm.flushed'


    @listenWindowResize()

    @on "ReceivedClickElsewhere", =>
      @setFocus no
      KD.getSingleton('windowController').removeLayer this

    @on "KDObjectWillBeDestroyed", @bound "clearBackoffTimeout"


    window.addEventListener "blur",  => @terminal.setFocused no
    window.addEventListener "focus", => @setFocus @focused


    @getElement().addEventListener "mousedown", (event) =>
      @terminal.mousedownHappened = yes
    , yes

    @forwardEvent @terminal, 'command'

    KD.mixpanel "Open Webterm, click", {
      machineName : @getMachine().getName()
    }

    @getDelegate().on 'KDTabPaneActive', => @terminal.updateSize yes

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

    if @reconnectionInProgress
      return console.info "reconnection is in progress"

    @reconnectionInProgress = yes

    options = @generateOptions()
    options.mode = mode

    kite = @getKite()
    kite.webtermConnect(options).then (remote) =>

      @setOption "session", remote.session
      @terminal.eventHandler = (data)=>
        @emit "WebTermEvent", data

      @terminal.server = remote
      @sessionId = remote.session

      @emit "WebTermConnected", remote
      @reconnectionInProgress = false

    .catch (err) =>

      KD.utils.warnAndLog "terminal: webtermConnect error",
        { hostnameAlias: @getMachine().getName(), reason:err?.message, options }

      if err.code is "ErrInvalidSession"

        @reconnectionInProgress = false
        @emit 'TerminalCanceled',
          machineId : @getMachine().uid
          sessionId : @getOptions().session
          error     : err

        return

      else

        @reconnectionInProgress = false
        throw err


  connectToTerminal: ->

    @appStorage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'

    @appStorage.fetchStorage =>

      @appStorage.setValue 'font'      , 'ubuntu-mono' if not @appStorage.getValue('font')?
      @appStorage.setValue 'fontSize'  , 14 if not @appStorage.getValue('fontSize')?
      @appStorage.setValue 'theme'     , 'green-on-black' if not @appStorage.getValue('theme')?
      @appStorage.setValue 'visualBell', false if not @appStorage.getValue('visualBell')?
      @appStorage.setValue 'scrollback', 1000 if not @appStorage.getValue('scrollback')?
      @updateSettings()

      {mode} = @getOptions()
      @webtermConnect mode

    KD.getSingleton("kiteController").on "KiteError", (err) =>

      warn "kite error:", err

      @reconnected = no
      {code, serviceGenericName} = err

      machineName = @getMachine().getName()

      ErrorLog.create "KiteError", {
        code, serviceGenericName, machineName, reason: err?.message
      }

  # FIXME GG
  #     if code is 503 and serviceGenericName.indexOf("kite-os") is 0
  #       @reconnectAttemptFailed serviceGenericName, vmName

  # reconnectAttemptFailed: (serviceGenericName, vmName) ->
  #   return  if @reconnected or not serviceGenericName

  #   kiteController = KD.getSingleton "kiteController"
  #   [prefix, kiteType, kiteRegion] = serviceGenericName.split "-"
  #   serviceName = "~#{kiteType}-#{kiteRegion}~#{vmName}"

  #   @setBackoffTimeout(
  #     @bound "attemptToReconnect"
  #     @bound "handleConnectionFailure"
  #   )

  #   kiteController.kiteInstances[serviceName]?.cycleChannel()

  # attemptToReconnect: ->
  #   return  if @reconnected
  #   @getDelegate().notify
  #     cssClass  : "error"
  #     title     : "Trying to reconnect your Terminal"
  #     duration  : 2 * 60 * 1000 # 2 mins

  #   hasResponse  = no

  #   {vm} = @getOptions()
  #   {hostnameAlias, region} = vm
  #   {vmController, kontrol} = KD.singletons

  #   kite =
  #     if KD.useNewKites
  #     then kontrol.kites.terminal[hostnameAlias]
  #     else vmController.terminalKites[hostnameAlias]
  #   kite?.webtermGetSessions().then (sessions) =>
  #     hasResponse = yes
  #     return if @reconnected

  #   @handleReconnect()

  # handleReconnect: (force = no) ->
  #   return  if not force and @reconnected

  #   @clearBackoffTimeout()
  #   options =
  #     session : @sessionId
  #     vm      : @getOption('vm')

  #   @emit "WebTermNeedsToBeRecovered", options
  #   @reconnected = yes

  # handleConnectionFailure: ->
  #   title = "Sorry, something is wrong with our backend."

  #   ErrorLog.create title

  #   return if @failedToReconnect
  #   @reconnected       = no
  #   @failedToReconnect = yes
  #   @clearBackoffTimeout()
  #   @getDelegate().notify
  #     title     : title
  #     cssClass  : "error"
  #     duration  : 15 * 1000 # 15 secs


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
    @terminal.scrollToBottom(no)
    @terminal.controlCodeReader.visualBell = @appStorage.getValue 'visualBell'
    @terminal.setScrollbackLimit @appStorage.getValue 'scrollback'

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

  _windowDidResize: (event) ->
    @terminal.windowDidResize()

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

  initBackoff: KDBroker.Broker::initBackoff
