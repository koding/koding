class WebTermAppView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @dirty = KD.utils.dict()

    @initedPanes = KD.utils.dict()

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate          : this
      addPlusHandle     : yes

    @tabView = new ApplicationTabView
      delegate                  : this
      tabHandleContainer        : @tabHandleContainer
      resizeTabHandles          : yes
      closeAppWhenAllTabsClosed : no

    @tabView.on 'PaneDidShow', (pane, index) =>
      @_windowDidResize()
      {terminalView} = pane.getOptions()

      @initPane pane

      terminalView.terminal?.scrollToBottom()

      KD.utils.defer -> terminalView.setKeyView()

      @fetchStorage (storage) -> storage.setValue 'activeIndex', index

    @on "KDObjectWillBeDestroyed", ->
      KD.getSingleton("mainView").disableFullscreen()

    @messagePane = new KDCustomHTMLView
      cssClass   : 'message-pane'
      partial    : 'Loading Terminal...'

    @tabView.on 'AllTabsClosed', =>
      @setMessage "All tabs are closed. <a class='plus' href='#'>Click to open a new Terminal</a>.", no, yes

    @tabView
      .on('PaneRemoved', @bound 'updateSessions')
      .on('TabsSorted', @bound 'updateSessions')

  initPane: (pane) ->
    return if pane.id of @initedPanes
    @initedPanes[pane.id] = yes

    {terminalView} = pane.getOptions()

    terminalView.once 'viewAppended', => @emit "ready"
    terminalView.once "WebTerm.terminated", (server) =>
      if not pane.isDestroyed and @tabView.getActivePane() is pane
        @tabView.removePane pane

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

  restoreTabs: (vmName) ->
    @fetchStorage (storage) =>
      sessions = storage.getValue 'savedSessions'
      activeIndex = storage.getValue 'activeIndex'
      if sessions?.length
        for session in sessions
          [vmName, sessionId] = session.split ':'
          @createNewTab { vmName, session: sessionId, mode: 'resume' }
        activePane = @tabView.getPaneByIndex activeIndex ? 0
        @tabView.showPane activePane
        { terminalView } = activePane.getOptions()
        terminalView.setKeyView()
      else
        @addNewTab vmName

  checkVM:->

    vmController = KD.getSingleton 'vmController'
    vmController.fetchDefaultVmName (vmName)=>

      KD.mixpanel "Open Webterm, click", {vmName}

      unless vmName
        return @setMessage "It seems you don't have a VM to use with Terminal."

      WebTermView.setTerminalTimeout vmName, 15000
      , => @restoreTabs vmName
      , (->)
      , =>
        KD.mixpanel "Open Webterm, fail", {vmName}
        KD.logToExternalWithTime "oskite: Can't open Webterm", vmName
        @emit 'message', """https://koding.slack.com/files/sinan/F025B6R70/pasted_image_at_2014_02_20_05_34pm.png
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
    @messagePane.hide()

    defaultOptions =
      testPath    : "webterm-tab"
      delegate    : this

    terminalView   = new WebTermView (KD.utils.extend defaultOptions, options)

    terminalView.on 'message', @bound 'setMessage'

    terminalView.on 'WebTermConnected', @bound 'updateSessions'

    WebTermView.setTerminalTimeout options.vmName, 15000, ->
      terminalView.connectToTerminal()
    , =>
      KD.utils.defer => @addNewTab vmName
    , =>
      KD.mixpanel "Open Webterm, fail", {vmName}
      KD.logToExternalWithTime "oskite: Can't open Webterm", vmName
      @setMessage """
        <p>Couldn't connect to your VM.</p>
        <br>
        <p>Preparing your VM can take anywhere from
        5 to 60 seconds, depending on load.</p>
        <br>
        <p>Please wait, then <a class='plus' href='#'>try again</a>.</p>
        """, no, yes

    @appendTerminalTab terminalView

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
      sessions = @tabView.panes.map (pane) =>
        { terminalView } = pane.getOptions()
        sessionId = terminalView.sessionId ? terminalView.getOption 'session'
        vmName = terminalView.getOption 'vmName'
        "#{ vmName }:#{ sessionId }"
      storage.setValue 'savedSessions', sessions
      storage.setValue 'activeIndex', activeIndex

  addNewTab: (vmName)->

    if @_secondTab
      KD.mixpanel "Open new Webterm tab, success"

    @_secondTab   = yes

    unless vmName
      @utils.defer =>

        vmc = KD.getSingleton 'vmController'
        if vmc.vms.length > 1
          return  if @vmselection and not @vmselection.isDestroyed
          @vmselection = new VMSelection
          @vmselection.once 'VMSelected', ({ hostnameAlias }) =>
            @createNewTab vmName: hostnameAlias, mode: 'create'
        else
          @createNewTab vmName: vmc.vms.first.hostnameAlias, mode: 'create'

    else
      @createNewTab vmName: vmName, mode: 'create'

  pistachio: ->
    """
    {{> @tabHandleContainer}}
    {{> @messagePane}}
    {{> @tabView}}
    """

class ChromeTerminalBanner extends JView
  constructor: (options={}, data)->

    options.domId = "chrome-terminal-banner"

    super options, data

    @descriptionHidden = yes

    @mainView = KD.getSingleton "mainView"
    @router   = KD.getSingleton "router"
    @finder   = KD.getSingleton "finderController"

    @mainView.on "fullscreen", (state)=>
      unless state then @hide() else @show()

    @register   = new CustomLinkView
      cssClass: "action"
      title   : "Register"
      click   : => @revealKoding "/Register"

    @login      = new CustomLinkView
      cssClass: "action"
      title   : "Login"
      click   : => @revealKoding "/Login"

    @whatIsThis = new CustomLinkView
      cssClass : "action"
      title    : "What is This?"
      click    : =>
        if @descriptionHidden
          @description.show()
        else
          @description.hide()
        @descriptionHidden = not @descriptionHidden

    @description = new KDCustomHTMLView
      tagName : "p"
      cssClass: "hidden"
      partial : """
      This is a complete virtual environment provided by Koding. <br>
      Koding is a social development environment. <br>
      Visit and see it in action at <a href="http://koding.com" target="_blank">http://koding.com</a>
      """

    @revealer = new CustomLinkView
      cssClass : "action"
      title    : "Reveal Koding"
      click    : => @revealKoding()

  revealKoding: (route)->
    @finder.mountVm "vm-0.#{KD.nick()}.guests.kd.io" unless KD.isLoggedIn()
    @router.handleRoute route if route
    @mainView.disableFullscreen()

  pistachio: ->
    if KD.isLoggedIn()
      """
      <span class="koding-icon"></span>
      <div class="actions">
        {{> @revealer}}
      </div>
      """
    else
      """
      <span class="koding-icon"></span>
      <div class="actions">
        {{> @register}}
        {{> @login}}
        {{> @whatIsThis}}
      </div>
      {{> @description}}
      """
