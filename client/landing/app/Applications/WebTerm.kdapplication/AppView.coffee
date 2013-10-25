class WebTermView extends KDView

  constructor: (options = {}, data) ->

    super options, data
    @initBackoff()

  viewAppended: ->
    @container = new KDView
      cssClass : "console ubuntu-mono black-on-white"
      bind     : "scroll"
    @container.on "scroll", =>
      @container.$().scrollLeft 0
    @addSubView @container

    @terminal = new WebTerm.Terminal @container.$()
    # KD.track "userOpenedTerminal", KD.getSingleton("groupsController").getCurrentGroup()
    @options.advancedSettings ?= no
    if @options.advancedSettings
      @advancedSettings = new KDButtonViewWithMenu
        style         : 'editor-advanced-settings-menu'
        icon          : yes
        iconOnly      : yes
        iconClass     : "cog"
        type          : "contextmenu"
        delegate      : @
        itemClass     : WebtermSettingsView
        click         : (pubInst, event)-> @contextMenu event
        menu          : @getAdvancedSettingsMenuItems.bind @
      @addSubView @advancedSettings

    @terminal.sessionEndedCallback = (sessions) =>
      @emit "WebTerm.terminated"
      @clearConnectionAttempts()

    @terminal.setTitleCallback = (title) =>
      #@tabPane.setTitle title

    @terminal.flushedCallback = =>
      @emit 'WebTerm.flushed'

    @listenWindowResize()

    @focused = true

    @on "ReceivedClickElsewhere", =>
      @focused = false
      @terminal.setFocused false
      KD.getSingleton('windowController').removeLayer @

    @on "KDObjectWillBeDestroyed", @bound "clearConnectionAttempts"

    $(window).on "blur", =>
      @terminal.setFocused false

    $(window).on "focus", =>
      @terminal.setFocused @focused

    $(document).on "paste", (event) =>
      if @focused
        @terminal.server.input event.originalEvent.clipboardData.getData("text/plain")
        @setKeyView()

    @bindEvent 'contextmenu'

    @appStorage = new AppStorage 'WebTerm', '1.0'
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
        vmName        : delegateOptions.vmName
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

    KD.getSingleton("status").once "reconnected", => @handleReconnect()

    kiteErrorCallback = (err) =>
      @reconnected               = no
      {code, serviceGenericName} = err

      if code is 503 and serviceGenericName.indexOf("kite-os") is 0
        @reconnectAttemptFailed serviceGenericName, @getDelegate().getOption "vmName"

    kiteController = KD.getSingleton "kiteController"
    kiteController.on "KiteError", kiteErrorCallback

    @on "KiteErrorBindingNeedsToBeRemoved", =>
      kiteController.off "KiteError", kiteErrorCallback

  reconnectAttemptFailed: (serviceGenericName, vmName) ->
    return  if @reconnected or not serviceGenericName

    kiteController = KD.getSingleton "kiteController"
    [prefix, kiteType, kiteRegion] = serviceGenericName.split "-"
    serviceName = "~#{kiteType}-#{kiteRegion}~#{vmName}"

    @setBackoffTimeout(
      @bound "atttemptToReconnect"
      @bound "handleConnectionFailure"
    )

    kiteController.kiteInstances[serviceName]?.cycleChannel()

  atttemptToReconnect: ->
    return  if @reconnected
    @reconnectingNotification ?= new KDNotificationView
      type      : "mini"
      title     : "Trying to reconnect your Terminal"
      duration  : 2 * 60 * 1000 # 2 mins
      container : @container

    vmController = KD.getSingleton "vmController"
    hasResponse  = no

    vmController.info @getDelegate().getOption("vmName"), (err, res) =>
      hasResponse = yes
      @handleReconnect()
      @clearConnectionAttempts()

    @utils.wait 500, => @reconnectAttemptFailed() unless hasResponse

  clearConnectionAttempts: ->
    @emit "KiteErrorBindingNeedsToBeRemoved"
    @clearBackoffTimeout()

  handleReconnect: ->
    return  if @reconnected
    @clearConnectionAttempts()
    options =
      session  : @sessionId
      joinUser : KD.nick()

    @reinitializeWebTerm options
    @reconnectingNotification?.destroy()
    @reconnected = yes

  reinitializeWebTerm: (options = {}) ->
    options.delegate = @getDelegate()
    @addSubView webterm = new WebTermView options

    webterm.on "WebTermConnected", =>
      @getSubViews().first.destroy() # TODO: refactor this, don't use subviews

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
    super
    KD.getSingleton('windowController').addLayer @
    @focused = true
    @terminal.setFocused true

  click: ->
    @setKeyView()
    @textarea?.remove()

  keyDown: (event) ->
    @listenFullscreen event
    @terminal.keyDown event

  keyPress: (event) ->
    @terminal.keyPress event

  keyUp: (event) ->
    @terminal.keyUp event

  contextMenu: (event) ->
    # invisible textarea will be placed under the cursor when rightclick
    @createInvisibleTextarea event
    @setKeyView()
    event

  createInvisibleTextarea:(eventData)->

    # Get selected Text for cut/copy
    if window.getSelection
        selectedText = window.getSelection()
    else if document.getSelection
        selectedText = document.getSelection()
    else if document.selection
        selectedText = document.selection.createRange().text

    @textarea?.remove()
    @textarea = $(document.createElement("textarea"))
    @textarea.css
      position  : "absolute"
      opacity   : 0
      # width     : "30px"
      # height    : "30px"
      # top       : eventData.offsetY-10
      # left      : eventData.offsetX-10
      width       : "100%"
      height      : "100%"
      top         : 0
      left        : 0
      right       : 0
      bottom      : 0
    @$().append @textarea

    # remove on any of these events
    @textarea.on 'copy cut paste', (event)=>
      @setKeyView()
      @utils.wait 1000, => @textarea.remove()
      yes

    if selectedText
      @textarea.val(selectedText.toString())
      @textarea.select()
    @textarea.focus()

    #remove 15sec later
    @utils.wait 15000, =>
      @textarea?.remove()

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