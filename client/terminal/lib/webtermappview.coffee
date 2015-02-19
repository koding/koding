kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDModalView = kd.ModalView
KDNotificationView = kd.NotificationView
KDTabPaneView = kd.TabPaneView
KDView = kd.View
mixpanel = require 'app/util/mixpanel'
isLoggedIn = require 'app/util/isLoggedIn'
WebtermSettingsView = require 'app/terminal/webtermsettingsview'
WebTermView = require 'app/terminal/webtermview'
JView = require 'app/jview'
ChromeTerminalBanner = require './chrometerminalbanner'
TerminalStartTab = require './terminalstarttab'
Encoder = require 'htmlencode'
ApplicationTabHandleHolder = require 'app/commonviews/applicationview/applicationtabhandleholder'
ApplicationTabView = require 'app/commonviews/applicationview/applicationtabview'


# Notes:                                  ~ GG
# RestoreTab functionality removed with
# 8c9f80cff24c93107de583cb864b0001f1e737af

module.exports = class WebTermAppView extends JView

  loadingPartial = 'Loading Terminal...'

  constructor: (options = {}, data) ->

    super options, data

    @machines = {}

    @dirty = kd.utils.dict()

    @initedPanes = kd.utils.dict()

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
      .on('TabsSorted',      @bound 'updateSessions')
      .on('PaneDidShow',     @bound 'handlePaneShown')

    @addStartTab()

    @on 'VMItemClicked',     @bound 'createNewTab'

    @on 'PlusHandleClicked', @bound 'handlePlusClick'
    @on 'WebTermConnected',  @bound 'updateSessions'
    @on 'TerminalClosed',    @bound 'removeSession'

    @on "SessionSelected", ({ machine, session })=>
      @createNewTab { machine, session, mode: 'resume' }

    @on "SessionRemoveRequested", ({ machine, session })=>
      @removeSession { machineId: machine.uid, sessionId: session }

    @on 'TerminalStarted', ->
      mixpanel "Open new Webterm, success"


  viewAppended: ->
    super

    {computeController} = kd.singletons
    computeController.fetchMachines (err, machines)=>

      machines.forEach (machine)=>
        @machines[machine.uid] = machine

    path = global.location.pathname + global.location.search + "?"
    mainController = kd.getSingleton("mainController")

    unless isLoggedIn()
      mainController.once "accountChanged.to.loggedIn", =>
        wc = kd.singleton 'windowController'
        wc.clearUnloadListeners()
        global.location.replace path


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
        kd.getSingleton("mainView").enableFullscreen()


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

    @fetchStorage (storage) ->
      storage.setValue 'activeIndex', index

    terminalView.terminal?.scrollToBottom()
    kd.utils.defer -> terminalView.setKeyView()


  fetchStorage: (callback) ->

    storage = kd.getSingleton('appStorageController').storage 'Terminal', '1.0.1'
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
          cssClass: "solid green medium"
          callback: ->
            remote.input "#{command}\n"
            modal.destroy()
        "Cancel":
          cssClass: "solid red medium"
          callback: ->
            modal.destroy()


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


  getAdvancedSettingsMenuView: (item, menu)->

    return  unless pane = @tabView.getActivePane()

    {terminalView} = pane.getOptions()
    settingsView = new KDView
      cssClass: "editor-advanced-settings-menu"
    settingsView.addSubView new WebtermSettingsView {
      menu, delegate: terminalView
    }

    return settingsView


  chromeAppMode: ->

    windowController = kd.getSingleton("windowController")
    mainController   = kd.getSingleton("mainController")

    # talking with chrome app
    if global.parent?.postMessage
      {parent} = global
      mainController.on "clientIdChanged", ->
        parent.postMessage "clientIdChanged", "*"

      parent.postMessage "fullScreenTerminalReady", "*"
      parent.postMessage "loggedIn", "*"  if isLoggedIn()

      @on "KDObjectWillBeDestroyed", ->
        parent.postMessage "fullScreenWillBeDestroyed", "*"

    @addSubView new ChromeTerminalBanner


  createNewTab: (options = {}) ->

    {shouldShow, session} = options

    # before creating new tab check for its existence
    # first and then show that pane if it is already opened
    pane = @findPane session
    return @tabView.showPane pane  if pane

    options.testPath = "webterm-tab"
    options.delegate = this

    terminalView = new WebTermView options

    @emit 'TerminalStarted'

    @appendTerminalTab terminalView, shouldShow
    terminalView.connectToTerminal()

    @forwardEvent terminalView, "WebTermConnected"
    @forwardEvent terminalView, "TerminalClosed"


  appendTerminalTab: (terminalView, shouldShow = yes) ->

    @forwardEvents terminalView, ['KeyViewIsSet', 'command']

    pane = new KDTabPaneView
      name         : 'Terminal'
      terminalView : terminalView

    @tabView.addPane pane, shouldShow
    pane.addSubView terminalView

    # FIXME GG
    # terminalView.on "WebTermNeedsToBeRecovered", ({vm, session}) =>

    #   @createNewTab {
    #     vm, session, mode: 'resume', shouldShow : no
    #   }

    #   title = "Reconnected to Terminal"
    #   Metric.create title, vm
    #   @notify {title}

    #   pane.destroySubViews()
    #   @tabView.removePane pane

    terminalView.once 'TerminalCanceled', ({ machineId }) =>
      @tabView.removePane pane
      unless @dirty[machineId]
        @tabView.off 'AllTabsClosed'
        @dirty[machineId] = yes

    # terminalView.once 'KDObjectWillBeDestroyed', => @tabView.removePane pane

  updateSessions: ->

    storage = (kd.getSingleton 'appStorageController').storage 'Terminal', '1.0.1'
    storage.fetchStorage =>

      activeIndex = @tabView.getActivePaneIndex()
      sessions = []

      @tabView.panes.forEach (pane) =>
        { terminalView } = pane.getOptions()
        return unless terminalView

        sessionId = terminalView.sessionId ? terminalView.getOption 'session'

        if sessionId
          machineId = terminalView.getMachine().uid
          sessions.push "#{ machineId }:#{ sessionId }"
        else
          kd.info "There is terminal pane but no sessionId is set."

      storage.setValue 'savedSessions', sessions
      storage.setValue 'activeIndex', activeIndex


  removeSession: ({machineId, sessionId}) ->

    @updateSessions()

    machine = @machines[machineId]
    machine.getBaseKite().webtermKillSession

      session: sessionId

    .then (response) =>

      kd.info "Terminal session removed from #{machineId} klient kite"
      @emit 'SessionListChanged'

    .catch (err) ->
      kd.warn err


  findPane: (session) ->

    foundPane = null
    @tabView.panes.forEach (pane) =>
      { terminalView } = pane.getOptions()
      return unless terminalView
      sessionId = terminalView.sessionId ? terminalView.getOption 'session'
      return foundPane = pane  if session is sessionId

    return foundPane


  handlePlusClick:->

    # FIXME ~GG
    # machine = @machines.first
    # @createNewTab { machine, mode:'create' }


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
