class WebTermView extends KDView

  constructor: (options = {}, data) ->
    super options, data

    @initBackoff()

  viewAppended: ->

    @container = new KDView
      cssClass : "console ubuntu-mono green-on-black"
      bind     : "scroll"
    @container.on "scroll", =>
      @container.$().scrollLeft 0
    @addSubView @container

    @terminal = new WebTerm.Terminal @container
    @options.advancedSettings ?= no
    if @options.advancedSettings
      @advancedSettings = new KDButtonViewWithMenu
        style         : 'editor-advanced-settings-menu'
        icon          : yes
        iconOnly      : yes
        iconClass     : "cog"
        type          : "contextmenu"
        delegate      : this
        itemClass     : WebtermSettingsView
        click         : (pubInst, event)-> @contextMenu event
        menu          : @getAdvancedSettingsMenuItems.bind this
      @addSubView @advancedSettings

    @terminal.sessionEndedCallback = (sessions) =>
      @emit "WebTerm.terminated"
      @clearConnectionAttempts()

    @terminal.flushedCallback = =>
      @emit 'WebTerm.flushed'

    @listenWindowResize()

    @on "ReceivedClickElsewhere", =>
      @setFocus no
      KD.getSingleton('windowController').removeLayer this

    @on "KDObjectWillBeDestroyed", @bound "clearConnectionAttempts"

    window.addEventListener "blur",  => @terminal.setFocused no
    window.addEventListener "focus", => @setFocus @focused

    @getElement().addEventListener "mousedown", (event) =>
      @terminal.mousedownHappened = yes
    , yes

    @forwardEvent @terminal, 'command'

    vmName = @getOption 'vmName'

    KD.mixpanel "Open Webterm, click", {vmName}

    vmController = KD.getSingleton 'vmController'
    vmController.info vmName, KD.utils.getTimedOutCallback (err, vm, info)=>
      if err
        KD.logToExternal "oskite: Error opening Webterm", vmName, err
        KD.mixpanel "Open Webterm, fail", {vmName}

      if info?.state is 'RUNNING' then @connectToTerminal()
      else
        vmController.start vmName, (err, state)=>
          warn "Failed to turn on vm:", err  if err
          KD.utils.defer => @connectToTerminal()
      KD.mixpanel "Open Webterm, success", {vmName}

    , =>
      KD.mixpanel "Open Webterm, fail", {vmName}
      KD.logToExternalWithTime "oskite: Can't open Webterm", vmName
      @emit 'message', "Couldn't connect to your VM, please try again later. <a class='close' href='#'>close this</a>", no, yes
    , 10000

    @getDelegate().on 'KDTabPaneActive', =>
      # @terminal.setSize 100, 100
      @terminal.updateSize yes

    @setKeyView()

  connectToTerminal: ->
    @appStorage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'
    @appStorage.fetchStorage =>
      @appStorage.setValue 'font'      , 'ubuntu-mono' if not @appStorage.getValue('font')?
      @appStorage.setValue 'fontSize'  , 14 if not @appStorage.getValue('fontSize')?
      @appStorage.setValue 'theme'     , 'green-on-black' if not @appStorage.getValue('theme')?
      @appStorage.setValue 'visualBell', false if not @appStorage.getValue('visualBell')?
      @appStorage.setValue 'scrollback', 1000 if not @appStorage.getValue('scrollback')?
      @updateSettings()

      delegateOptions = @getDelegate().getOptions()
      myOptions       = @getOptions()

      params =
        remote      : @terminal.clientInterface
        sizeX       : @terminal.sizeX
        sizeY       : @terminal.sizeY
        joinUser    : myOptions.joinUser  ? delegateOptions.joinUser
        session     : myOptions.session   ? delegateOptions.session
        mode        : myOptions.mode      ? 'create'

      KD.getSingleton("vmController").run
        method        : "webterm.connect",
        vmName        : myOptions.vmName or delegateOptions.vmName
        withArgs      : params
      , (err, remote) =>
        if err
          warn err

          if err.code is "ErrInvalidSession"
            @emit 'TerminalCanceled',
              vmName: myOptions.vmName
              sessionId: myOptions.session
              error: err
            return
          else throw err

        @terminal.eventHandler = (data)=> @emit "WebTermEvent", data
        @terminal.server = remote
        @sessionId = remote.session
        @emit "WebTermConnected", remote

    KD.getSingleton("status").on "reconnected", =>
      @handleReconnect yes

    KD.getSingleton("kiteController").on "KiteError", (err) =>
      @reconnected = no
      {code, serviceGenericName} = err

      if code is 503 and serviceGenericName.indexOf("kite-os") is 0
        @reconnectAttemptFailed serviceGenericName, (@getOption 'vmName') or @getDelegate().getOption "vmName"

  reconnectAttemptFailed: (serviceGenericName, vmName) ->
    return  if @reconnected or not serviceGenericName

    kiteController = KD.getSingleton "kiteController"
    [prefix, kiteType, kiteRegion] = serviceGenericName.split "-"
    serviceName = "~#{kiteType}-#{kiteRegion}~#{vmName}"

    @setBackoffTimeout(
      @bound "attemptToReconnect"
      @bound "handleConnectionFailure"
    )

    kiteController.kiteInstances[serviceName]?.cycleChannel()

  attemptToReconnect: ->
    return  if @reconnected
    @reconnectingNotification ?= new KDNotificationView
      type      : "mini"
      title     : "Trying to reconnect your Terminal"
      duration  : 2 * 60 * 1000 # 2 mins
      container : @container

    vmController = KD.getSingleton "vmController"
    hasResponse  = no

    vmController.info (@getOption 'vmName') or @getDelegate().getOption("vmName"), (err, res) =>
      hasResponse = yes
      return if @reconnected
      @handleReconnect()
      @clearConnectionAttempts()

    @utils.wait 500, => @reconnectAttemptFailed() unless hasResponse

  clearConnectionAttempts: ->
    @clearBackoffTimeout()

  handleReconnect: (force = no) ->
    return  if not force and @reconnected

    @clearConnectionAttempts()
    options =
      session  : @sessionId
      joinUser : KD.nick()

    @reinitializeWebTerm options
    @reconnectingNotification?.destroy()
    @reconnected = yes

  reinitializeWebTerm: (options = {}) ->
    return  if @reconnected
    @emit "WebTermNeedsToBeRecovered", options

  handleConnectionFailure: ->
    return if @failedToReconnect
    @reconnectingNotification?.destroy()
    @reconnected       = no
    @failedToReconnect = yes
    @clearConnectionAttempts()
    new KDNotificationView
      type      : "mini"
      title     : "Sorry, something is wrong with our backend."
      container : @container
      cssClass  : "error"
      duration  : 15 * 1000 # 15 secs

  destroy: ->
    super
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
