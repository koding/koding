kd            = require 'kd'
globals       = require 'globals'
whoami        = require 'app/util/whoami'
KodingKontrol = require 'app/kite/kodingkontrol'

module.exports = class InstallKdModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'install-kd-modal'
    options.title    = 'Install kd'
    options.width    = 690
    options.height   = 310
    options.overlay  = yes

    super options, data

    @createElements()
    @generateCode()


  createElements: ->

    @addSubView new kd.CustomHTMLView
      cssClass: 'bg'
      partial : '<div class="extra"></div>'

    @addSubView @content = new kd.CustomHTMLView
      tagName: 'section'
      cssClass: 'has-markdown'
      partial: """
        <p><code>kd</code> is a command line program that lets you use your local IDEs with your VMs. Copy and paste the command below in your PC's terminal. Please note:</p>
        <p class='middle'>1. <code>sudo</code> permission required.</p>
        <p class='middle'>2. Works only on OSX and Linux.</p>
        <p class='middle'>3. <code>kd</code> is currently in beta.</p>
      """
    # Commenting out learn, until the article is ready.
    #<span>
    #  <a href="http://learn.koding.com/guides/kd" target="_blank">Learn more about this feature.</a>
    #</span>

    @addSubView @code = new kd.CustomHTMLView
      tagName  : 'div'
      cssClass : 'code'

    @code.addSubView @loader = new kd.LoaderView
      size: { width : 16 }
      showLoader  : yes


  generateCode: ->

    whoami().fetchOtaToken (err, token) =>
      return @handleError err  if err

      @updateContentViews token


  updateContentViews: (token) ->
    cmd = if globals.config.environment in ['dev', 'default', 'sandbox']
      "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; curl -sL https://sandbox.kodi.ng/c/d/kd | bash -s #{token}"
    else
      "curl -sL https://kodi.ng/c/p/kd | bash -s #{token}"

    @loader.destroy()
    @code.addSubView @input = new kd.InputView
      defaultValue : cmd
      click        : =>
        @showTooltip()
        @input.selectAll()

    @code.addSubView @selectButton = new kd.CustomHTMLView
      cssClass : 'select-all'
      partial  : '<span></span>SELECT'
      click    : =>
        @showTooltip()
        @input.selectAll()


  showTooltip: ->

    shortcut = 'Ctrl+C'

    if navigator.userAgent.indexOf('Mac OS X') > -1
      shortcut = 'Cmd+C'

    @input.setTooltip { title: "Press #{shortcut} to copy", placement: 'above' }
    @input.tooltip.show()

    kd.singletons.windowController.addLayer @input
    @input.on 'ReceivedClickElsewhere', =>
      @input.unsetTooltip()


  handleError: (err) ->

    console.warn "Couldn't fetch otatoken:", err  if err

    @loader.destroy()
    return @code.updatePartial 'Failed to fetch one time access token.'


  destroy: ->

    @input?.unsetTooltip()

    super
