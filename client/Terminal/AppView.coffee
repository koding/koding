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
      .on('TabsSorted',    @bound 'updateSessions')
      .on('PaneDidShow',   @bound 'handlePaneShown')

    @addStartTab()

    @on 'VMItemClicked',     @bound 'prepareAndRunTerminal'
    @on 'PlusHandleClicked', @bound 'handlePlusClick'
    @on 'WebTermConnected',  @bound 'updateSessions'
    @on 'TerminalClosed',    @bound 'removeSession'

    @on 'TerminalStarted', ->
      KD.mixpanel "Open new Webterm, success"

    {vmController} = KD.singletons
    vmController.on 'vm.progress.error', => @notify cssClass : 'error'

    @on "SessionSelected", ({vm, session}) => @createNewTab {vm, session, mode: 'resume'}

    {vmController} = KD.singletons
    {terminalKites} = vmController
    vmController.ready @bound 'restoreTabs'

  restoreTabs: ->
    @fetchStorage (storage) =>
      sessions = storage.getValue 'savedSessions'
      return  unless sessions?.length

      @notify
        title     : "Checking for previous sessions"
        cssClass  : "success"

      # group sessions by alias
      aliases = []
      sessions.forEach (session) ->
        [alias, sessionId] = session.split ':'
        aliases.push alias  unless alias in aliases

      # fetch vms and store in an object with the key of alias
      KD.singletons.vmController.fetchGroupVMs no, (err, vms) =>
        return warn err  if err
        vmList = {}
        vms.map (vm) ->
          vmList[vm.hostnameAlias] = vm

        {dash} = Bongo

        # fetch all active vm sessions via terminal kites
        activeSessions = []
        {vmController, kontrol} = KD.singletons
        kites =
          if KD.useNewKites
          then kontrol.kites.terminal
          else vmController.terminalKites
        queue = aliases.map (alias)->->
          # when we have sessions from another xontext in appStorage
          # prevent restoring sessions of terminals in that context
          kites[alias]?.webtermGetSessions().then (sessions) =>
            activeSessions = activeSessions.concat sessions
            queue.fin()
          .catch (err) ->
            warn err
            queue.fin()

        # after all active sessions are fetched, compare them with last open sessions
        sessionRestored = no
        dash queue, =>
          sessions.forEach (session) =>
            [alias, sessionId] = session.split ':'
            if sessionId in activeSessions
              sessionRestored = yes
              @createNewTab
                vm         : vmList[alias]
                session    : sessionId
                mode       : 'resume'
                shouldShow : no

          unless sessionRestored
            @notify
              title     : 'Your previous sessions are no longer online since \
                           your VM is turned off due to inactivity. If you \
                           want always on VMs, you can upgrade your plan'
              cssClass  : 'fail'


  initPane: (pane) ->

    return if pane.id of @initedPanes

    @initedPanes[pane.id] = yes

    {terminalView} = pane.getOptions()

    terminalView.once 'viewAppended', => @emit "ready"
    terminalView.once "WebTerm.terminated", (server) =>
      if not pane.isDestroyed and @tabView.getActivePane() is pane
        @tabView.removePane pane


  handlePaneShown:(pane, index)->

    {terminalView} = pane.getOptions()

    return  unless terminalView

    @initPane pane
    terminalView.terminal?.scrollToBottom()
    KD.utils.defer -> terminalView.setKeyView()
    @fetchStorage (storage) -> storage.setValue 'activeIndex', index


  fetchStorage: (callback) ->
    storage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'
    storage.fetchStorage -> callback storage


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
    else
      terminalView.once "TerminalClosed", @bound "removeSession"
      terminalView.once 'WebTermConnected', runner

  handleQuery:(query)->
    pane = @tabView.getActivePane()
    {terminalView} = pane.getOptions()
    terminalView.terminal?.scrollToBottom()
    terminalView.once "TerminalClosed", @bound "removeSession"
    terminalView.once 'WebTermConnected', (remote)=>
      @emit "WebTermConnected"
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

    {shouldShow, session} = options
    {hostnameAlias: vmName, region} = options.vm

    # before creating new tab check for its existence first and then show that pane if it is already opened
    pane = @findPane session

    return @tabView.showPane pane  if pane

    defaultOptions =
      testPath    : "webterm-tab"
      delegate    : this

    terminalView   = new WebTermView (KD.utils.extend defaultOptions, options)

    @emit 'TerminalStarted'

    @appendTerminalTab terminalView, shouldShow
    terminalView.connectToTerminal()
    @forwardEvent terminalView, "WebTermConnected"
    @forwardEvent terminalView, "TerminalClosed"

  addStartTab:->

    pane = new KDTabPaneView
      name          : 'intro'
      tabHandleView : new KDCustomHTMLView
        tagName     : 'span'
        cssClass    : 'home'
      view          : @startTab = new TerminalStartTab
        tagName     : 'main'
        delegate    : this
      closable      : no

    @tabView.addPane pane

  appendTerminalTab: (terminalView, shouldShow = yes) ->

    @forwardEvents terminalView, ['KeyViewIsSet', 'command']

    pane = new KDTabPaneView
      name          : 'Terminal'
      terminalView  : terminalView

    @tabView.addPane pane, shouldShow
    pane.addSubView terminalView

    terminalView.on "WebTermNeedsToBeRecovered", ({vm, session}) =>
      @createNewTab {vm, session, mode: 'resume', shouldShow : no}

      title = "Reconnected to Terminal"
      Metric.create title, vm
      @notify {title}

      pane.destroySubViews()
      @tabView.removePane pane

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
        {hostnameAlias} = terminalView.getOption 'vm'
        sessions.push "#{ hostnameAlias }:#{ sessionId }"
      storage.setValue 'savedSessions', sessions
      storage.setValue 'activeIndex', activeIndex

  findPane: (session) ->
    foundPane = null
    @tabView.panes.forEach (pane) =>
      { terminalView } = pane.getOptions()
      return unless terminalView
      sessionId = terminalView.sessionId ? terminalView.getOption 'session'
      return foundPane = pane  if session is sessionId

    return foundPane

  removeSession: ({vmName, sessionId}) ->
    @updateSessions()
    {vmController, kontrol} = KD.singletons
    terminalKites =
      if KD.useNewKites
      then kontrol.kites.terminal
      else vmController.terminalKites

    terminalKites[vmName].webtermKillSession
      session: sessionId
    .then (response) ->
      log 'session removed from terminal kite'
    .catch (err) ->
      warn err

  addNewTab: (vm) ->

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
      vm = vmc.vms.first

      unless vm
        ErrorLog.create "terminal: handlePlusClick error", {reason:"0 vms"}
        return

      osKite =
        if KD.useNewKites
        then vmc.kites.oskite[vm.hostnameAlias]
        else vmc.kites[vm.hostnameAlias]

      state = osKite.recentState?.state

      if state is 'RUNNING'
      then @prepareAndRunTerminal vm
      else
        ErrorLog.create "terminal: handlePlusClick error",
          {reason: "vm has unknown state", osKiteState: state}

        @notify cssClass : 'error'

  prepareAndRunTerminal: (vm, mode = 'create') ->
    {vmController} = KD.singletons
    osKite =
      if KD.useNewKites
      then vmController.kites.oskite[vm.hostnameAlias]
      else vmController.kites[vm.hostnameAlias]

    {recentState}  = osKite

    state = osKite.recentState?.state

    if state is 'RUNNING'
      @createNewTab {vm, mode}
    else if state in ['STOPPED', 'FAILED']
      osKite?.vmOn().catch @bound "handlePrepareError"
    else
      ErrorLog.create "terminal: prepareAndRunTerminal error",
        {vm, reason: "vm has unknown state", osKiteState: state}

      @notify cssClass : 'error'
      osKite?.vmOff()

  handlePrepareError: (err) ->
    title = err?.message

    if title and /limit reached/.test title
      title += ". Please upgrade to run more VMs."

    numberOfVms = Object.keys(KD.singletons.vmController.vmsInfo).length
    ErrorLog.create err?.message, {numberOfVms}

    new KDNotificationView {title}

  pistachio: ->
    """
    {{> @tabHandleContainer}}
    {{> @tabView}}
    """


  notify: do ->

    notification = null

    (options = {}) =>

      notification?.destroy()

      options.title     or= "We can not communicate with your VM, please try again later!"
      options.type      or= "mini"
      options.cssClass  or= "success"
      options.duration   ?= 5000

      notification = new KDNotificationView options
