kd              = require 'kd'
whoami          = require 'app/util/whoami'
globals         = require 'globals'
actions         = require 'app/flux/environment/actions'
KodingKontrol   = require 'app/kite/kodingkontrol'
isTeamReactSide = require 'app/util/isTeamReactSide'
CopyTooltipView = require 'app/components/common/copytooltipview'
ContentModal = require 'app/components/contentModal'
copyToClipboard = require 'app/util/copyToClipboard'

module.exports = class AddManagedMachineModal extends ContentModal

  constructor: (options = {}, data) ->

    options.cssClass = 'add-managed-vm content-modal'
    options.title    = 'Add Your Own Machine'
    options.width    = 720
    options.overlay  = yes

    super options, data

    @createElements()
    @generateCode()


  createElements: ->

    @addSubView @main = new kd.CustomHTMLView
      tagName : 'main'

    @main.addSubView new kd.CustomHTMLView
      cssClass: 'bg'
      partial : '<div class="extra"></div>'

    @main.addSubView @content = new kd.CustomHTMLView
      tagName: 'section'
      partial: """
        <p>Run the command below to connect your Ubuntu machine to Koding. Please note:</p>
        <p class='middle'>1. the machine should have a public IP address</p>
        <p class='middle'>2. you should have root access</p>
        <p class='middle'>3. no firewall should be running on the machine</p>
        <span>
          <strong>Leave this dialogue box open</strong> until you see a notification in the sidebar
          that the connection has been successful.
          <a href="https://koding.com/docs/connect-your-own-machine-to-koding" target="_blank">Learn more about this feature.</a>
        </span>
      """

    @main.addSubView @code = new kd.CustomHTMLView
      tagName  : 'div'
      cssClass : 'code'

    @code.addSubView @loader = new kd.LoaderView
      size: { width : 16 }
      showLoader  : yes


  machineFoundCallback: (info, machine) ->

    if isTeamReactSide()
      actions.showManagedMachineAddedModal info, machine._id
    else
      kd.singletons.mainView.activitySidebar.showManagedMachineAddedModal info, machine

    @destroy()


  generateCode: ->

    { computeController } = kd.singletons

    computeController.ready =>

      whoami().fetchOtaToken (err, token) =>
        return @handleError err  if err

        @updateContentViews token


  updateContentViews: (token) ->

    { environment } = globals.config

    if environment is 'production' and \
    location.hostname.indexOf("latest.#{globals.config.domains.base}") > -1
      kontrolUrl = "export KONTROLURL=#{KodingKontrol.getKontrolUrl()}; "
    else
      kontrolUrl = if environment in ['dev', 'default', 'sandbox']
      then "export KONTROLURL=#{KodingKontrol.getKontrolUrl()} CHANNEL=devmanaged; "
      else ''

    cmd = "#{kontrolUrl}curl -sL https://kodi.ng/s | bash -s #{token}"

    @loader.destroy()

    @inputWrapper = new kd.View

    @inputWrapper.addSubView @input = new kd.InputView
      defaultValue : cmd
      click        : => @copyCode()

    @code.addSubView new kd.CustomHTMLView
      cssClass : 'select-all'
      partial  : '<span></span>COPY'
      click    : => @copyCode()

    @code.addSubView @inputWrapper

    { computeController } = kd.singletons
    computeController.managedKiteChecker.addListener @bound 'machineFoundCallback'

    kd.utils.wait 20000, =>
      @main.addSubView new kd.LoaderView
        cssClass : 'machine-search-loader'
        showLoader: yes
        size: { width: 26 }

      @setClass 'polling'

  copyCode: ->

    @input.selectAll()

    copyToClipboard @inputWrapper.getElement()


  showTooltip: ->

    @copyTooltipView.showTooltip()
    kd.singletons.windowController.addLayer @input

    @input.on 'ReceivedClickElsewhere', @copyTooltipView.bound 'unsetTooltip'


  handleError: (err) ->

    console.warn "Couldn't fetch otatoken:", err  if err

    if err.message.indexOf('confirm your email address') > -1
      new kd.NotificationView { title : err.message }
      return @destroy()

    @loader.destroy()
    return @code.updatePartial 'Failed to fetch one time access token.'


  handleUsageLimit: ->

    @code.destroy()
    @content.updatePartial '''
      <h>
        'Uh oh! You already have a managed machine!'
      </h>
      <p>
        Free Koding accounts are limited to adding one external machine and
        you already have one connected. Paid accounts are allowed to add unlimited external machines.
      </p>
    '''

    @content.addSubView new kd.CustomHTMLView
      tagName : 'p'
      partial : 'Please <a href="/Pricing">upgrade</a> to be able to add more.'
      click   : (event) =>
        return  unless event.target.tagName is 'A'

        # Don't require 'ComputeHelpers' on top. If you do that,
        # you will get a circular dependency error from browserify.
        ComputeHelpers  = require '../computehelpers'

        kd.singletons.paymentController.once 'PaymentWorkflowFinishedSuccessfully', ->
          ComputeHelpers.handleNewMachineRequest { provider: 'managed' }

        @destroy()

    @setClass 'error'


  destroy: ->

    super

    cc = kd.singletons.computeController
    cc.managedKiteChecker.removeListener @bound 'machineFoundCallback'
    kd.singletons.router.back()  unless isTeamReactSide()
