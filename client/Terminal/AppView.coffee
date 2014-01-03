class WebTermView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @_vmName = options.vmName  if options.vmName

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
        menu          : @getAdvancedSettingsMenuItems.bind @
      @addSubView @advancedSettings

    @terminal.sessionEndedCallback = (sessions) =>
      @emit "WebTerm.terminated"
      @clearConnectionAttempts()

    @terminal.flushedCallback = =>
      @emit 'WebTerm.flushed'

    @listenWindowResize()

    @focused = true

    @on "ReceivedClickElsewhere", =>
      @focused = false
      @terminal.setFocused false
      KD.getSingleton('windowController').removeLayer @

    @on "KDObjectWillBeDestroyed", @bound "clearConnectionAttempts"

    window.addEventListener "blur", =>
      @terminal.setFocused false

    window.addEventListener "focus", =>
      @terminal.setFocused @focused

    document.addEventListener "paste", (event) =>
      if @focused
        @terminal?.server.input event.clipboardData.getData("text/plain")
        @setKeyView()


    @forwardEvent @terminal, 'command'

    vmName = @_vmName
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
      @setMessage "Couldn't connect to your VM, please try again later. <a class='close' href='#'>close this</a>", no, yes
    , 10000

    @getDelegate().on 'KDTabPaneActive', =>
      @terminal.setSize 100, 100
      @terminal.updateSize yes

  connectToTerminal:->
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

      KD.getSingleton("vmController").run
        method        : "webterm.connect",
        vmName        : @_vmName or delegateOptions.vmName
        withArgs      :
          remote      : @terminal.clientInterface
          sizeX       : @terminal.sizeX
          sizeY       : @terminal.sizeY
          joinUser    : myOptions.joinUser or delegateOptions.joinUser
          session     : myOptions.session  or delegateOptions.session
          noScreen    : delegateOptions.noScreen
      , (err, remote) =>
        if err
          warn err
          if err.message is "Invalid session identifier."
            return @reinitializeWebTerm()

        @terminal.eventHandler = (data)=> @emit "WebTermEvent", data
        @terminal.server       = remote
        @setKeyView()
        @emit "WebTermConnected", remote
        @sessionId = remote.session

    KD.getSingleton("status").on "reconnected", =>
      @handleReconnect yes

    KD.getSingleton("kiteController").on "KiteError", (err) =>
      @reconnected               = no
      {code, serviceGenericName} = err

      if code is 503 and serviceGenericName.indexOf("kite-os") is 0
        @reconnectAttemptFailed serviceGenericName, @_vmName or @getDelegate().getOption "vmName"

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

    vmController.info @_vmName or @getDelegate().getOption("vmName"), (err, res) =>
      hasResponse = yes
      return if @reconnected
      @handleReconnect()
      @clearConnectionAttempts()

    @utils.wait 500, => @reconnectAttemptFailed() unless hasResponse

  clearConnectionAttempts: ->
    @clearBackoffTimeout()

  handleReconnect: (force = no) ->
    unless force
      return  if @reconnected

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
    @focused = true
    @terminal.setFocused true
    @emit 'KeyViewIsSet'

  click: ->
    @setKeyView()

  keyDown: (event) ->
    @listenFullscreen event
    @terminal.keyDown event

  keyPress: (event) ->
    @terminal.keyPress event

  keyUp: (event) ->
    @terminal.keyUp event

  _windowDidResize: (event) ->
    @terminal.windowDidResize()

  getAdvancedSettingsMenuItems:->
    settings      :
      type        : 'customView'
      view        : new WebtermSettingsView
        delegate  : @

  listenFullscreen: (event)->
    requestFullscreen = (event.metaKey or event.ctrlKey) and event.keyCode is 13
    if requestFullscreen
      mainView = KD.getSingleton "mainView"
      mainView.toggleFullscreen()
      event.preventDefault()

  initBackoff: KDBroker.Broker::initBackoff
