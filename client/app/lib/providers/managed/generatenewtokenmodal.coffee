kd        = require 'kd'
globals   = require 'globals'
whoami    = require 'app/util/whoami'


module.exports = class GenerateNewTokenModal extends kd.ModalView

  constructor: (options = {}, data) ->

    kd.warn 'Constructing new token modal'

    options.cssClass = 'generate-new-token'
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
      partial: """
        <p>kd is a command line program that lets you use your local IDEs with your VMs. Copy and paste the command below in a terminal. Please note:</p>
        <p class='middle'>1. sudo permission required.</p>
        <p class='middle'>2. Works only on OSX and Linux.</p>
        <p class='middle'>3. kd is currently in beta.</p>

        <span>
          <a href="http://learn.koding.com/guides/kd" target="_blank">Learn more about this feature.</a>
        </span>
      """

    @addSubView @code = new kd.CustomHTMLView
      tagName  : 'div'
      cssClass : 'code'

    @code.addSubView @loader = new kd.LoaderView
      size: width : 16
      showLoader  : yes


  generateCode: ->

    whoami().fetchOtaToken (err, token) =>
      return @handleError err  if err

      @updateContentViews token


  updateContentViews: (token) ->

    kontrolUrl = if globals.config.environment in ['dev', 'sandbox']
    then "export KONTROLURL=#{globals.config.newkontrol.url}; "
    else ''

    cmd = "#{kontrolUrl}curl -sL https://kodi.ng/d/kd | bash -s #{token}"

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

    @input.setTooltip title: "Press #{shortcut} to copy", placement: 'above'
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


