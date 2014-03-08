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
      .on('AllTabsClosed', @bound 'handleAllPanesClosed')

    @messagePane = new KDCustomHTMLView
      cssClass   : 'message-pane hidden'
      partial    : loadingPartial

    @addStartTab()


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

    @setFailTimer()

    @initPane pane
    terminalView.terminal?.scrollToBottom()
    KD.utils.defer -> terminalView.setKeyView()
    @fetchStorage (storage) -> storage.setValue 'activeIndex', index


  handleAllPanesClosed:->

    @setMessage """
      All tabs are closed. <a class='plus' href='#'>Click to open a new Terminal</a>.
      """
    , no, yes



  setFailTimer: do -> alreadySet = null; ->

    return  if alreadySet

    # if we still have the same message after 15 seconds assuming
    # all checks have failed and showing a warning to make user
    # try again. - SY
    messageTimer = KD.utils.wait 15000, =>
      alreadySet = yes
      if @messagePane.$().text() is loadingPartial
        @setMessage "Couldn't open your terminal. <a class='plus' href='#'>Click here to try again</a>.", no, yes
    @on 'TerminalStarted', =>
      alreadySet = yes
      KD.utils.killWait messageTimer


  setMessage:(msg, light = no, bindClick = no)->

    @messagePane.updatePartial msg
    if light
    then @messagePane.setClass   'light'
    else @messagePane.unsetClass 'light'
    @messagePane.show()

    if bindClick
      @messagePane.once 'click', (event)=>
        KD.utils.stopDOMEvent event
        if $(event.target).hasClass 'close'
          KD.singleton('router').back()
          KD.singleton('appManager').quitByName 'Terminal'
        else if $(event.target).hasClass 'plus'
          @addNewTab()
          @messagePane.hide()

  fetchStorage: (callback) ->
    storage = KD.getSingleton('appStorageController').storage 'Terminal', '1.0.1'
    storage.fetchStorage -> callback storage

  restoreTabs: (vm) ->

    notification = new KDNotificationView
      title     : "Checking for previous sessions"
      type      : "mini"
      cssClass  : "success"
      duration  : 5000

    @fetchStorage (storage) =>
      notification.destroy()
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

  checkVM:->

    vmController = KD.getSingleton 'vmController'
    vmController.fetchDefaultVm (err, vm) =>
      return KD.showError err  if err?

      { region, hostnameAlias: vmName } = vm

      kite = vmController.kites[vmName]

      KD.mixpanel "Open Webterm, click", {vmName}

      unless vmName
        return @setMessage "It seems you don't have a VM to use with Terminal."

      WebTermView.setTerminalTimeout vmName, 15000
      , =>
        kite.webtermGetSessions().then (sessions) ->
          console.log sessions, sessions.length
        @messagePane.hide()
      , =>
        @messagePane.hide()
      , =>
        KD.mixpanel "Open Webterm, fail", {vmName}
        KD.logToExternalWithTime "oskite: Can't open Webterm", vmName
        @emit 'TerminalFailed'
        @emit 'message', """
          <p>Couldn't connect to your VM.</p>
          <br>
          <p>Preparing your VM can take anywhere from
          5 to 60 seconds, depending on load.</p>
          <br>
          <p>Please wait, then <a class='plus' href='#'>try again</a>.</p>
          """, no, yes

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
    @checkVM()
    path = location.pathname + location.search + "?"
    mainController = KD.getSingleton("mainController")

    unless KD.isLoggedIn()
      mainController.once "accountChanged.to.loggedIn", =>
        wc = KD.singleton 'windowController'
        wc.clearUnloadListeners()
        location.replace path


  createNewTab: (options = {}) ->
    { hostnameAlias: vmName, region } = options.vm

    debugger  if 'string' is typeof options.vm

    @messagePane.hide()

    defaultOptions =
      testPath    : "webterm-tab"
      delegate    : this

    terminalView   = new WebTermView (KD.utils.extend defaultOptions, options)

    terminalView.on 'message', @bound 'setMessage'

    terminalView.on 'WebTermConnected', @bound 'updateSessions'

    WebTermView.setTerminalTimeout vmName, 15000
    , =>
      terminalView.connectToTerminal()

      kite = KD.getSingleton("vmController").getKite options.vm
      kite.on 'destroy', =>
        console.error "Couldn't connect to your VM. Trying to reconnect...(err:oskite)"
        terminalView.webtermConnect("resume")

      # todo do not leak events
      KD.kite.mq.on "broker.error", (err)=>
        console.error "Couldn't connect to your VM. Trying to reconnect...(err:broker)"
        if err.code is 404
          terminalView.webtermConnect("resume")

      @messagePane.hide()
      @emit 'TerminalStarted'
    , =>
      KD.utils.defer =>
        @addNewTab options.vm
        @messagePane.hide()
        @emit 'TerminalStarted'
    , =>
      KD.mixpanel "Open Webterm, fail", {vmName}
      KD.logToExternalWithTime "oskite: Can't open Webterm", vmName
      @emit 'TerminalFailed'
      @setMessage """
        <p>Couldn't connect to your VM.</p>
        <br>
        <p>Preparing your VM can take anywhere from
        5 to 60 seconds, depending on load.</p>
        <br>
        <p>Please wait, then <a class='plus' href='#'>try again</a>.</p>
        """, no, yes

    @appendTerminalTab terminalView

  MESSAGE_MAP =
    'started'                : 'Checking VM state'
    'vm is already prepared' : 'READY'

  addStartTab:->

    pane = new KDTabPaneView
      name          : 'intro'
      tabHandleView : new KDCustomHTMLView
        tagName     : 'span'
        cssClass    : 'home'
      view          : view = new KDView tagName : 'main'
      closable      : no

    view.addSubView header = new KDCustomHTMLView
      tagName : 'h1'
      partial : 'This is where the magic happens!'

    view.addSubView help = new KDCustomHTMLView
      tagName : 'h2'
      partial : 'Terminal allows you to interact directly with your VM.'

    view.addSubView new KDCustomHTMLView
      tagName : 'figure'
      partial : """<iframe src="//www.youtube.com/embed/DmjWnmSlSu4?origin=https://koding.com&showinfo=0&rel=0&theme=dark&modestbranding=1&autohide=1&loop=1" width="100%" height="100%" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>"""

    view.addSubView help = new KDCustomHTMLView
      tagName : 'h3'
      partial : 'Your VMs'

    view.addSubView vmWrapper = new KDCustomHTMLView
      tagName : 'ul'

    {vmController} = KD.singletons
    vmController.fetchVMs (err, vms)=>
      if err
        return new KDNotificationView title : "Couldn't fetch your VMs"

      vms.sort (a,b)-> a.hostnameAlias > b.hostnameAlias

      vms.forEach (vm)=>
        vmWrapper[vm.hostnameAlias] = new KDCustomHTMLView
          tagName : 'li'
          partial : "<figure></figure>#{vm.hostnameAlias.replace 'koding.kd.io', 'kd.io'}<i></i>"
          click   : => @addNewTab vm
        vmWrapper.addSubView vmWrapper[vm.hostnameAlias]

      vmController.on 'vm.start.progress', (vmAlias, update)->
        {message} = update
        return  if message is 'FINISHED'
        niceMessage = MESSAGE_MAP[message.toLowerCase()]
        vmWrapper[vmAlias].unsetClass 'ready'
        vmWrapper[vmAlias].setClass 'ready'  if niceMessage is 'READY'
        vmWrapper[vmAlias].$('i').text niceMessage or message


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
        @setMessage """
          Sorry, your terminal sessions on #{ vmName } are dead. <a href='#' class='plus'>Open a new session.</a>
          """, no, yes
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

    if @_secondTab
      KD.mixpanel "Open new Webterm tab, success"

    @_secondTab   = yes

    if vm?
      @createNewTab { vm }, mode: 'create'

    else
      @utils.defer =>

        vmc = KD.getSingleton 'vmController'
        if vmc.vms.length > 1
          return  if @vmselection and not @vmselection.isDestroyed
          @vmselection = new VMSelection
          @vmselection.once 'VMSelected', (vm) =>
            @createNewTab { vm }, mode: 'create'
        else
          @createNewTab vm: vmc.vms.first, mode: 'create'

  pistachio: ->
    """
    {{> @tabHandleContainer}}
    {{> @messagePane}}
    {{> @tabView}}
    """

