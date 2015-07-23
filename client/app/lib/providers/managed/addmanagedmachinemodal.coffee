kd        = require 'kd'
globals   = require 'globals'
checkFlag = require 'app/util/checkFlag'
whoami    = require 'app/util/whoami'


module.exports = class AddManagedMachineModal extends kd.ModalView

  constructor: (options = {}, data) ->

    return  unless checkFlag ['super-admin', 'super-digitalocean']

    options.cssClass = 'add-managed-vm'
    options.title    = 'Add Your Own Machine'
    options.width    = 690
    options.height   = 310

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
        <p>Run the command below to connect to your machine to Koding. Note, machine should:</p>
        <p class="middle">1. have a public IP address</p>
        <p>2. you should have root access</p>
        <span>
          <strong>Leave this dialogue box open</strong> until you see a notification in the sidebar
          that the connection has been successful.
          <a href="http://learn.koding.com/connect_your_machine" target="_blank">Learn more about this feature.</a>
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

        if used >= limit
          return @handleUsageLimit()

        whoami().fetchOtaToken (err, token) =>
          return @handleError err  if err

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

          computeController.managedKiteChecker.addListener @bound 'machineFoundCallback'

          @createPollLoader()


  showTooltip: ->

    @input.setTooltip title: 'Press Cmd+C to copy', placement: 'above'
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


  createPollLoader: ->

    kd.utils.wait 20000, =>
      @addSubView new kd.LoaderView showLoader: yes, size: width: 26
      @setClass 'polling'


  destroy: ->

    super

    cc = kd.singletons.computeController
    cc.managedKiteChecker.removeListener @bound 'machineFoundCallback'
