kd        = require 'kd'
globals   = require 'globals'
whoami    = require 'app/util/whoami'


module.exports = class AddManagedMachineModal extends kd.ModalView

  constructor: (options = {}, data) ->

    options.cssClass = 'add-managed-vm'
    options.title    = 'Add Your Own Machine'
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
        <p>Run the command below to connect your Ubuntu machine to Koding. Please note:</p>
        <p class='middle'>1. the machine should have a public IP address</p>
        <p class='middle'>2. you should have root access</p>
        <p class='middle'>3. no firewall should be running on the machine</p>
        <span>
          <strong>Leave this dialogue box open</strong> until you see a notification in the sidebar
          that the connection has been successful.
          <a href="http://learn.koding.com/guides/connect-your-machine" target="_blank">Learn more about this feature.</a>
        </span>
      """

    @addSubView @code = new kd.CustomHTMLView
      tagName  : 'div'
      cssClass : 'code'

    @code.addSubView @loader = new kd.LoaderView
      size: width : 16
      showLoader  : yes


  machineFoundCallback: (info, machine) ->

    kd.singletons.mainView.activitySidebar.showManagedMachineAddedModal info, machine
    @destroy()


  generateCode: ->

    { computeController } = kd.singletons

    computeController.ready =>

      computeController.fetchPlanCombo 'managed', (err, userPlanInfo) =>

        return @handleError err  if err

        { plan, usage, plans } = userPlanInfo
        limit = plans[plan].managed
        used  = usage.total

        return @handleUsageLimit()  if used >= limit

        whoami().fetchOtaToken (err, token) =>
          return @handleError err  if err

          @updateContentViews token


  updateContentViews: (token) ->

    kontrolUrl = if globals.config.environment in ['dev', 'sandbox']
    then "export KONTROLURL=#{globals.config.newkontrol.url}; "
    else ''

    cmd = "#{kontrolUrl}curl -sL https://kodi.ng/s | bash -s #{token}"

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

    { computeController } = kd.singletons
    computeController.managedKiteChecker.addListener @bound 'machineFoundCallback'

    kd.utils.wait 20000, =>
      @addSubView new kd.LoaderView showLoader: yes, size: width: 26
      @setClass 'polling'


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


  handleUsageLimit: ->

    @setTitle 'Uh oh! You already have a managed machine!'

    @code.destroy()
    @content.updatePartial """
      <p>
        Free Koding accounts are limited to adding one external machine and
        you already have one connected. Paid accounts are allowed to add unlimited external machines.
      </p>
      <p>Please <a href="/Pricing">upgrade</a> to be able to add more.</p>
    """

    @setClass 'error'


  destroy: ->

    @input.unsetTooltip()

    super

    cc = kd.singletons.computeController
    cc.managedKiteChecker.removeListener @bound 'machineFoundCallback'


