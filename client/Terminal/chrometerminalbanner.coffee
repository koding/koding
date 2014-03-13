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

  destroy:->
    KD.getSingleton("mainView").disableFullscreen()
    super