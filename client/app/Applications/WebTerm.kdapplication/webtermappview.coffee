class WebTermAppView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @listenWindowResize()

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate: this

    @tabView = new ApplicationTabView
      delegate           : @
      tabHandleContainer : @tabHandleContainer
      resizeTabHandles   : yes

    @tabView.on 'PaneDidShow', (pane) =>
      @_windowDidResize()
      {webTermView} = pane.getOptions()
      webTermView.on 'viewAppended', -> webTermView.terminal.setFocused yes
      webTermView.once 'viewAppended', => @emit "ready"
      webTermView.terminal?.setFocused yes
      KD.utils.defer -> webTermView.setKeyView()

      webTermView.on "WebTerm.terminated", (server) =>
        if not pane.isDestroyed and @tabView.getActivePane() is pane
          @tabView.removePane pane

    @on "KDObjectWillBeDestroyed", ->
      KD.getSingleton("mainView").disableFullscreen()

  showApprovalModal: (remote, command)->
    modal = new KDModalView
      title   : "Warning!"
      content : """
      <div class="modalformline">
        <p>
          If you <strong>don't trust this app</strong>, or if you clicked on this
          link <strong>not knowing what it would do</strong> - be careful it <strong>can
          damage/destroy</strong> your Koding VM.
        </p>
      </div>
      <div class="modalformline">
        <p>
          This URL is set to execute the command below:
        </p>
      </div>
      <pre>
        #{Encoder.XSSEncode command}
      </pre>
      """
      buttons :
        "Run" :
          cssClass: "modal-clean-gray"
          callback: ->
            remote.input "#{command}\n"
            modal.destroy()
        "Cancel":
          cssClass: "modal-cancel"
          callback: ->
            modal.destroy()

  getAdvancedSettingsMenuView: (item, menu)->
    pane = @tabView.getActivePane()
    {webTermView} = pane.getOptions()
    settingsView = new KDView
      cssClass: "editor-advanced-settings-menu"
    settingsView.addSubView new WebtermSettingsView
      menu    : menu
      delegate: webTermView

    return settingsView

  handleQuery:(query)->
    pane = @tabView.getActivePane()
    {webTermView} = pane.getOptions()
    webTermView.once 'WebTermConnected', (remote)=>

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
    windowController.clearUnloadListeners "window"

    # talking with chrome app
    if window.parent?.postMessage
      windowController.on "clientIdChanged", =>
        window.parent.postMessage "clientIdChanged", "*"

      window.parent.postMessage "fullScreenTerminalReady", "*"
      window.parent.postMessage "loggedIn", "*"  if KD.isLoggedIn()

      @on "KDObjectWillBeDestroyed", ->
        window.parent.postMessage "fullScreenWillBeDestroyed", "*"

    @addSubView new ChromeTerminalBanner

  _windowDidResize:->
    # 10px being the application page's padding
    @tabView.setHeight @getHeight() - @tabHandleContainer.getHeight() - 10

  viewAppended: ->
    super
    @addNewTab()

  addNewTab: ->
    webTermView = new WebTermView
      testPath: "webterm-tab"
      delegate: this

    pane = new KDTabPaneView
      name: 'Terminal'
      webTermView: webTermView

    @tabView.addPane pane
    pane.addSubView webTermView

  pistachio: ->
    """
      {{> @tabHandleContainer}}
      {{> @tabView}}
    """

class ChromeTerminalBanner extends JView
  constructor: (options={}, data)->

    options.domId = "chrome-terminal-banner"

    super options, data

    @mainView = KD.getSingleton "mainView"
    @router   = KD.getSingleton "router"
    @finder   = KD.getSingleton "finderController"

    @mainView.on "fullscreen", (state)=>
      unless state then @hide() else @show()

    @register   = new KDCustomHTMLView
      tagName : "a"
      cssClass: "action"
      partial : "Register"
      click   : => @revealKoding "/Register"

    @login      = new KDCustomHTMLView
      tagName : "a"
      cssClass: "action"
      partial : "Login"
      click   : => @revealKoding "/Login"

    @whatIsThis = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "action"
      partial  : "What is This?"
      click    : =>
        @hidden = not @hidden
        if @hidden
          @description.show()
        else
          @description.hide()

    @description = new KDCustomHTMLView
      tagName: "p"
      partial: """
      This is a complete virtual environment provided by Koding. <br>
      Koding is a social development environment. <br>
      Visit and see it in action at <a href="http://koding.com" target="_blank">http://koding.com</a>
      """
    @description.hide()

    @revealer = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "action"
      partial  : "Reveal Koding"
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