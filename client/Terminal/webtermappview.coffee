class WebTermAppView extends JView

  constructor: (options = {}, data) ->

    super options, data

    @tabHandleContainer = new ApplicationTabHandleHolder
      delegate          : this
      addPlusHandle     : no

    @tabView = new ApplicationTabView
      delegate                  : this
      tabHandleContainer        : @tabHandleContainer
      resizeTabHandles          : yes
      closeAppWhenAllTabsClosed : no

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

    @messagePane = new KDCustomHTMLView
      cssClass   : 'message-pane'
      partial    : 'Loading Terminal...'

    @tabView.on 'AllTabsClosed', =>
      @setMessage """
        All tabs are closed. You can create a new
        Terminal by clicking (+) Plus button on top left.
      """, yes

  setMessage:(msg, light = no, bindClose = no)->
    @messagePane.updatePartial msg
    if light
    then @messagePane.setClass   'light'
    else @messagePane.unsetClass 'light'
    @messagePane.show()
    if bindClose
      @messagePane.once 'click', ->
        KD.singleton('router').back()
        KD.singleton('appManager').quitByName 'Terminal'

  checkVM:->

    vmController = KD.getSingleton 'vmController'
    vmController.fetchDefaultVmName (vmName)=>

      KD.mixpanel "Click open Webterm", {vmName}

      unless vmName
        return @setMessage "It seems you don't have a VM to use with Terminal."

      vmController.info vmName, KD.utils.getTimedOutCallback (err, vm, info)=>

        @addNewTab vmName  if info?.state is 'RUNNING'
        KD.mixpanel "Opened Webterm", {vmName}

      , =>
        KD.mixpanel "Can't open Webterm", {vmName}
        @setMessage "Couldn't connect to your VM, please try again later. <a href='#'>close this</a>", no, yes
      , 5000

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
    return  unless pane

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

  createNewTab:(vmName)->

    webTermView   = new WebTermView
      testPath    : "webterm-tab"
      delegate    : this
      vmName      : vmName

    pane          = new KDTabPaneView
      name        : 'Terminal'
      webTermView : webTermView

    @tabView.addPane pane
    pane.addSubView webTermView

    # webTermView.once 'KDObjectWillBeDestroyed', => @tabView.removePane pane

  addNewTab: (vmName)->

    @messagePane.hide()

    if not @tabHandleContainer.plusHandle
      @tabHandleContainer.addPlusHandle()

    if @_secondTab
      KD.mixpanel "Click open new Webterm tab"

    @_secondTab   = yes

    unless vmName
      @utils.defer =>

        vmc = KD.getSingleton 'vmController'
        if vmc.vms.length > 1
          vmselection = new VMSelection
          vmselection.once 'VMSelected', (vm)=> @createNewTab vm
        else
          @createNewTab vmc.vms.first

    else
      @createNewTab vmName


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
