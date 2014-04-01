class WebTermAppView extends JView

  loadingPartial = 'Loading Terminal...'

  constructor: (options = {}, data) ->

    super options, data

    @dirty = KD.utils.dict()

    @initedPanes = KD.utils.dict()

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate          : this
      addPlusHandle     : yes
      cssClass          : 'terminal'

    @tabView = new ApplicationTabView
      delegate                  : this
      tabHandleContainer        : @tabHandleContainer
      resizeTabHandles          : yes
      closeAppWhenAllTabsClosed : no

    @tabView
      .on('PaneRemoved',   @bound 'updateSessions')
      .on('TabsSorted',    @bound 'updateSessions')
      .on('PaneDidShow',   @bound 'handlePaneShown')

    @addStartTab()

    @on 'VMItemClicked',     @bound 'prepareAndRunTerminal'
    @on 'PlusHandleClicked', @bound 'handlePlusClick'

    {vmController} = KD.singletons
    vmController.on 'vm.progress.error', => notify cssClass : 'error'

  initPane: (pane) ->

    return if pane.id of @initedPanes

    @initedPanes[pane.id] = yes

    {terminalView} = pane.getOptions()

    terminalView.once 'viewAppended', => @emit "ready"
    terminalView.once "WebTerm.terminated", (server) =>
      if not pane.isDestroyed and @tabView.getActivePane() is pane
        @tabView.removePane pane


  handlePaneShown:(pane, index)->

    @_windowDidResize()
    {terminalView} = pane.getOptions()

    return  unless terminalView

    @initPane pane
    terminalView.terminal?.scrollToBottom()
    KD.utils.defer -> terminalView.setKeyView()
    @fetchStorage (storage) -> storage.setValue 'activeIndex', index


  fetchStorage: (callback) ->
    storage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'
    storage.fetchStorage -> callback storage

  restoreTabs: (vm) ->

    notify
      title     : "Checking for previous sessions"
      cssClass  : "success"

    @fetchStorage (storage) =>
      sessions = storage.getValue 'savedSessions'
      activeIndex = storage.getValue 'activeIndex'
      if sessions?.length
        for session in sessions
          [vmName, sessionId] = session.split ':'
          @createNewTab { vm, session: sessionId, mode: 'resume' }
        activePane = @tabView.getPaneByIndex activeIndex ? 0
        @tabView.showPane activePane
        { terminalView } = activePane.getOptions()
        terminalView.setKeyView()
      else
        @addNewTab vm


  showApprovalModal: (remote, command)->
    modal = new KDModalView
      cssClass: "terminal-command-warning"
      title   : "Warning!"
      content : """
      <p>
        If you <strong>don't trust this app</strong>, or if you clicked on this
        link <strong>not knowing what it would do</strong> - be careful it <strong>can
        damage/destroy</strong> your Koding VM.
      </p>
      <p>
        This URL is set to execute the command below:
      </p>
      <pre>
        #{Encoder.XSSEncode command}
      </pre>
      """
      buttons :
        "Run" :
          cssClass: "modal-clean-green"
          callback: ->
            remote.input "#{command}\n"
            modal.destroy()
        "Cancel":
          cssClass: "modal-clean-red"
          callback: ->
            modal.destroy()

  getAdvancedSettingsMenuView: (item, menu)->
    pane = @tabView.getActivePane()
    return  unless pane

    {terminalView} = pane.getOptions()
    settingsView = new KDView
      cssClass: "editor-advanced-settings-menu"
    settingsView.addSubView new WebtermSettingsView
      menu    : menu
      delegate: terminalView

    return settingsView

  runCommand:(_command)->
    pane = @tabView.getActivePane()
    {terminalView} = pane.getOptions()

    runner = =>
      terminalView.terminal.scrollToBottom()
      command = decodeURIComponent _command

      # FIXME Make it more elegant later.
      safeCommands = ['help this', 'help sudo', 'help ftp', 'help mysql',
                      'help programs', 'help phpmyadmin', 'help mongodb',
                      'help specs', 'help']

      if _command in safeCommands
        terminalView.terminal.server.input "#{command}\n"
      else
        @showApprovalModal terminalView.terminal, command

    if terminalView.terminal?.server?
    then runner()
    else terminalView.once 'WebTermConnected', runner

  handleQuery:(query)->

    console.trace()

    pane = @tabView.getActivePane()
    {terminalView} = pane.getOptions()
    terminalView.terminal?.scrollToBottom()
    terminalView.once 'WebTermConnected', (remote)=>

      if query.command
        command = decodeURIComponent query.command
        @showApprovalModal remote, command

      # chrome app specific settings
      if query.chromeapp

        query.fullscreen = yes # forcing fullscreen
        @chromeAppMode()

      if query.fullscreen
        KD.getSingleton("mainView").enableFullscreen()

  chromeAppMode: ->
    windowController = KD.getSingleton("windowController")
    mainController   = KD.getSingleton("mainController")

    # talking with chrome app
    if window.parent?.postMessage
      {parent} = window
      mainController.on "clientIdChanged", ->
        parent.postMessage "clientIdChanged", "*"

      parent.postMessage "fullScreenTerminalReady", "*"
      parent.postMessage "loggedIn", "*"  if KD.isLoggedIn()

      @on "KDObjectWillBeDestroyed", ->
        parent.postMessage "fullScreenWillBeDestroyed", "*"

    @addSubView new ChromeTerminalBanner

  viewAppended: ->
    super
    path = location.pathname + location.search + "?"
    mainController = KD.getSingleton("mainController")

    unless KD.isLoggedIn()
      mainController.once "accountChanged.to.loggedIn", =>
        wc = KD.singleton 'windowController'
        wc.clearUnloadListeners()
        location.replace path


  createNewTab: (options = {}) ->

    { hostnameAlias: vmName, region } = options.vm

    defaultOptions =
      testPath    : "webterm-tab"
      delegate    : this

    terminalView   = new WebTermView (KD.utils.extend defaultOptions, options)

    @emit 'TerminalStarted'

    @appendTerminalTab terminalView
    terminalView.connectToTerminal()

  addStartTab:->

    pane = new KDTabPaneView
      name          : 'intro'
      tabHandleView : new KDCustomHTMLView
        tagName     : 'span'
        cssClass    : 'home'
      view          : new TerminalStartTab
        tagName     : 'main'
        delegate    : this
      closable      : no

    @tabView.addPane pane

  appendTerminalTab: (terminalView) ->

    @forwardEvents terminalView, ['KeyViewIsSet', 'command']

    pane = new KDTabPaneView
      name          : 'Terminal'
      terminalView  : terminalView

    @tabView.addPane pane
    pane.addSubView terminalView

    terminalView.on "WebTermNeedsToBeRecovered", (options) =>
      options.delegate = this
      pane.destroySubViews()
      pane.addSubView new WebTermView options

    terminalView.once 'TerminalCanceled', ({ vmName }) =>
      @tabView.removePane pane
      unless @dirty[vmName]
        @tabView.off 'AllTabsClosed'
        @dirty[vmName] = yes

    # terminalView.once 'KDObjectWillBeDestroyed', => @tabView.removePane pane

  updateSessions: ->
    storage = (KD.getSingleton 'appStorageController').storage 'Terminal', '1.0.1'
    storage.fetchStorage =>
      activeIndex = @tabView.getActivePaneIndex()
      sessions = []
      @tabView.panes.forEach (pane) =>
        { terminalView } = pane.getOptions()
        return unless terminalView
        sessionId = terminalView.sessionId ? terminalView.getOption 'session'
        vmName = terminalView.getOption 'vmName'
        sessions.push "#{ vmName }:#{ sessionId }"
      storage.setValue 'savedSessions', sessions
      storage.setValue 'activeIndex', activeIndex

  addNewTab: (vm) ->

    KD.mixpanel "Open new Webterm tab, success"  if @_secondTab

    @_secondTab = yes
    mode        = 'create'

    @prepareAndRunTerminal vm, mode


  showVMSelection:->

    return  if @vmselection and not @vmselection.isDestroyed
    @vmselection = new VMSelection delegate : this


  handlePlusClick:->

    vmc = KD.getSingleton 'vmController'
    if vmc.vms.length > 1 then @showVMSelection()
    else
      vm            = vmc.vms.first
      osKite        = vmc.kites[vm.hostnameAlias]
      {recentState} = osKite
      if recentState?.state is 'RUNNING'
      then @prepareAndRunTerminal vm
      else notify cssClass : 'error'

  prepareAndRunTerminal: (vm, mode = 'create') ->
    {vmController} = KD.singletons
    osKite = 
      if KD.useNewKites
      then vmController.kites.oskite[vm.hostnameAlias]
      else vmController.kites[vm.hostnameAlias]
  
    {recentState}  = osKite

    if recentState?.state is 'RUNNING'
      @createNewTab {vm, mode}
    else if recentState?.state is 'STOPPED' or 'FAILED'
      osKite?.vmOn()
    else
      notify cssClass : 'error'
      osKite?.vmOff()

  pistachio: ->
    """
    {{> @tabHandleContainer}}
    {{> @tabView}}
    """


  notify = do ->

    notification = null

    (options = {}) =>

      notification?.destroy()

      options.title     or= "We can not communicate with your VM, please try again later!"
      options.type      or= "mini"
      options.cssClass  or= "success"
      options.duration   ?= 5000

      notification = new KDNotificationView options
