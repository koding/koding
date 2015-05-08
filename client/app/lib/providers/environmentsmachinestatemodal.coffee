$                       = require 'jquery'
Encoder                 = require 'htmlencode'

kd                      = require 'kd'
KDButtonView            = kd.ButtonView
KDLoaderView            = kd.LoaderView
KDCustomHTMLView        = kd.CustomHTMLView
KDProgressBarView       = kd.ProgressBarView
KDNotificationView      = kd.NotificationView
KDHitEnterInputView     = kd.HitEnterInputView

remote                  = require('../remote').getInstance()
Machine                 = require './machine'
ComputeHelpers          = require './computehelpers'
HelpSupportModal        = '../commonviews/helpsupportmodal'
ComputeController       = require './computecontroller'
EnvironmentsModalView   = require './environmentsmodalview'

whoami                  = require '../util/whoami'
isKoding                = require 'app/util/isKoding'
showError               = require '../util/showError'
trackEvent              = require 'app/util/trackEvent'
sendDataDogEvent        = require '../util/sendDataDogEvent'
environmentDataProvider = require 'app/userenvironmentdataprovider'


module.exports = class EnvironmentsMachineStateModal extends EnvironmentsModalView

  {
    Stopped, Running, NotInitialized, Terminated, Unknown, Pending,
    Starting, Building, Stopping, Rebooting, Terminating, Updating
  } = Machine.State

  EVENT_TIMEOUT = 2 * 60 * 1000 # 2 minutes.

  constructor: (options = {}, data) ->

    options.cssClass or= 'env-machine-state'
    options.width      = 440

    super options, data

    @addSubView @container = new KDCustomHTMLView cssClass: 'content-container'
    @machine = @getData()

    return @handleNoMachineFound()  unless @machine

    {jMachine}   = @machine
    @machineName = jMachine.label
    @machineId   = jMachine._id
    {@state}     = @machine.status
    @isManaged   = @machine.provider is 'managed'

    @showBusy()
    @show()

    {computeController} = kd.singletons

    computeController.ready => whoami().isEmailVerified (err, verified) =>

      kd.warn err  if err?

      if not verified
        @buildVerifyView()
      else
        kd.singletons.paymentController.subscriptions (err, subscription)=>
          kd.warn err  if err?
          if subscription?.state is 'expired'
          then @buildExpiredView subscription
          else @buildInitial()


  triggerEventTimer: (percentage)->

    if percentage isnt @_lastPercentage
      clearTimeout @eventTimer
    else unless @eventTimer
      @eventTimer = kd.utils.wait EVENT_TIMEOUT, @bound 'createRetry'

    @_lastPercentage = percentage


  clearEventTimer: ->

    @retryView?.destroy()
    @eventTimer = clearTimeout @eventTimer


  updateStatus: (event, task) ->

    return  if @_busy

    {status, percentage, error} = event

    if status is @state
      @updatePercentage percentage  if percentage?

    else
      @state = status

      if error

        if /NetworkOut/i.test error
          @customErrorMessage = "
            <p>You've reached your outbound network usage
            limit for this week.</p><span>
            Please upgrade your <a href='/Pricing'>plan</a> or
            <span class='contact-support'>contact support</span> for further
            assistance.</span>
          "

        unless error.code is ComputeController.Error.NotVerified
          @hasError = yes

      if not percentage?
        @switchToIDEIfNeeded()

      else if percentage is 100
        @completeCurrentProcess status

      else if task is 'reinit'
        @updatePercentage percentage
        @updateReinitState()

      else
        @clearEventTimer()
        @buildViews()

    @createStatusOutput event


  switchToIDEIfNeeded: (status = @state)->

    return no  unless status is Running
    @prepareIDE()
    @destroy()
    return yes


  updatePercentage: (percentage)->

    @triggerEventTimer percentage

    @progressBar?.updateBar Math.max percentage, 10
    @progressBar?.show()


  updateReinitState: ->

    @label?.updatePartial @getStateLabel()


  completeCurrentProcess: (status)->

    @clearEventTimer()

    return  if @switchToIDEIfNeeded status

    @progressBar?.updateBar 100
    @progressBar?.show()

    kd.utils.wait 500, => @buildViews()


  showBusy: (message) ->

    @_busy = message?

    @container.destroySubViews()

    @createStateLabel message ? "Loading..."
    @createLoading()


  buildInitial:->

    return @buildViews()  if @_initialBuiltOnce

    computeController = kd.getSingleton 'computeController'

    computeController.on "start-#{@machineId}", @bound 'updateStatus'
    computeController.on "build-#{@machineId}", @bound 'updateStatus'
    computeController.on "stop-#{@machineId}",  @bound 'updateStatus'

    # Stack build events
    if stack = computeController.findStackFromMachineId @machine._id
      computeController.on "apply-#{stack._id}", @bound 'updateStatus'

    computeController.on "reinit-#{@machineId}", (event) =>
      @updateStatus event, 'reinit'

    computeController.on "resize-#{@machineId}", (event) =>
      @updateStatus event, 'resize'

    if @isManaged
      computeController.on "public-#{@machineId}", @bound 'updateStatus'

    computeController.eventListener.followUpcomingEvents @machine

    @eventTimer = null
    @_lastPercentage = 0
    @_initialBuiltOnce = yes

    @container.destroySubViews()

    @createStateLabel "Checking state for <strong>#{@machineName or ''}</strong>..."

    @createLoading()
    @createFooter()

    if @getOption 'initial'

      currentState = @machine.status.state

      if currentState is NotInitialized
        @buildViews State: currentState
        return

      @triggerEventTimer 10

      kd.getSingleton 'computeController'
        .getKloud().info { @machineId, currentState }
        .then (response)=>

          kd.info "Initial info result:", response

          @buildViews response

        .catch (err)=>

          unless err?.code is ComputeController.Error.NotVerified
            kd.warn "Failed to fetch initial info:", err
            @hasError = yes

          @buildViews()

    else
      @buildViews()


  buildVerifyView: ->

    @container.destroySubViews()

    @codeEntryView = new KDHitEnterInputView
      type         : 'text'
      cssClass     : 'verify-pin-input'
      placeholder  : 'Enter code here'
      callback     : @bound 'verifyAccount'

    @button    = new KDButtonView
      title    : 'Verify account'
      cssClass : 'solid green medium'
      callback : @bound 'verifyAccount'

    @container.addSubView new KDCustomHTMLView
      cssClass : 'verify-message'
      partial  : "
        <p>Before you can access your VM, we need to verify your account.
        A verification email should already be in your inbox.
        If you did not receive it yet, you can request a
        <cite>new code</cite>.</p>
      "

      click    : (event)=>

        return  unless $(event.target).is 'cite'

        remote.api.JUser.verifyByPin resendIfExists: yes, (err)=>

          unless showError err

            @container.addSubView @retryView = new KDCustomHTMLView
              cssClass : 'error-message warning'
              partial  : """
                <p>Email sent, please check your inbox.</p>
              """

            kd.utils.wait 3000, @retryView.bound 'destroy'

    @container.addSubView @codeEntryView
    @container.addSubView @button


  buildExpiredView: (subscription, nextState)->

    plan = if subscription? then "(<b>#{subscription.planTitle}</b>)" else ""

    @container.destroySubViews()

    if nextState is "downgrade"

      @showBusy "Downgrading..."
      @downgradePlan (err)=>

        if err?
          kd.utils.wait 10000, =>
            @buildExpiredView subscription, "downgrade"
        else
          ComputeHelpers.handleNewMachineRequest provider: 'koding', (err)->
            global.location.reload yes

      return

    destroyVMs = nextState is "destroy-vms"

    @upgradeButton = new KDButtonView
      title    : 'Make Payment'
      cssClass : 'solid green medium plan-change-button'
      callback : -> kd.singletons.router.handleRoute '/Pricing'

    actionTitle = if destroyVMs then 'Delete All VMs' else 'Downgrade to Free'

    @actionButton = new KDButtonView
      title    : actionTitle
      cssClass : 'solid green medium plan-change-button downgrade'
      callback : =>

        if destroyVMs

          @showBusy "Deleting your VM(s)..."
          ComputeHelpers.destroyExistingMachines (err)=>
            @buildExpiredView subscription, "downgrade"
          , yes

        else

          @showBusy "Downgrading..."
          @downgradePlan (err) =>
            if err?
              @buildExpiredView subscription, "destroy-vms"
            else
              @_busy = no
              @buildInitial()

    @container.addSubView new KDCustomHTMLView
      cssClass : 'expired-message'
      partial  : if destroyVMs then "
        <h1>Delete all existing VMs</h1>
        <p>To be able to downgrade your current plan #{plan} to the
        <b>Free</b> plan, you need to delete all your existing VMs. This
        action will <b>destroy all your VMs, (including YOUR FILES) and
        cannot be UNDONE!</b> Are you sure you want to continue?</p>
      " else "
        <h1>Your Koding Paid Plan Has Expired</h1>
        <p>This happens when we cannot collect a payment. As a result,
        access to your VM is restricted.</p>
        <p>To continue, you can either make a payment to lift the
        restriction or downgrade to a free account. Downgrading will delete
        your existing VM(s) (and all the data inside them)
        and give you a new default VM.</p>
      "

    unless destroyVMs
      @container.addSubView @upgradeButton

    @container.addSubView @actionButton


  buildViews: (response)->

    return  if @_busy

    if response?.State?
      @state = response.State

    @container.destroySubViews()
    @container.unsetClass 'marketing-message'
    @progressBar = null

    if @state is 'NotFound'
      @createStateLabel "
        <h1>You don't have any VMs!</h1>
        <span>
          This can happen if you have deleted all your VMs or if your VM was automatically deleted due to inactivity. <a href='http://learn.koding.com/faq/inactive-vms' target='_blank'>Learn more</a> about inactive VM cleanup.
        </span>
      "
    else
      @createStateLabel()

    if @state in [ Stopped, NotInitialized, Unknown, 'NotFound' ]
      @createStateButton()
    else if @state in [ Starting, Building, Pending, Stopping,
                        Terminating, Updating, Rebooting ]
      percentage = response?.percentage
      @createProgressBar percentage
      @triggerEventTimer percentage
      @createMarketingMessage()  if @state is Starting
    else if @state is Terminated
      @label.destroy?()
      @createStateLabel "
        The VM <strong>#{@machineName or ''}</strong> was
        successfully deleted. Please select a new VM to operate on from
        the VMs list or create a new one.
      "
      @createStateButton()
    else if @state is Running
      @prepareIDE()
      @destroy()

    @createError()

    @createStatusOutput response


  statusMessagesMap  =
    'start started'  : 'Starting VM'
    'stop started'   : 'Stopping VM'
    'stop finished'  : 'VM is stopped'
    'start finished' : 'VM is ready'

  createStatusOutput: (response) ->

    message = response?.message

    if typeof message is 'string'
      message = statusMessagesMap[message] or message
      message = message.replace 'machine', 'VM'
      message = message.capitalize()

    if @logView
      @logView.updatePartial message
    else
      @addSubView @logView = new KDCustomHTMLView
        cssClass : 'stdout'
        partial  : message

    @logView[if message then 'setClass' else 'unsetClass'] 'in'



  getStateLabel: ->

    stateTexts       =
      Stopped        : if @isManaged then 'is not reachable.' else 'is turned off.'
      Starting       : 'is starting now.'
      Stopping       : 'is stopping now.'
      Pending        : 'is resizing now.'
      Running        : 'up and running.'
      Building       : 'is building now.'
      NotInitialized : 'is turned off.'
      Terminated     : 'is turned off.'
      Rebooting      : 'is rebooting.'
      Terminating    : 'is terminating.'
      Updating       : 'is updating now.'
      Unknown        : 'is turned off.'
      NotFound       : 'No machine found.' # additional class level
                                           # state to show a modal
                                           # for unknown routes.

    stateText = "<strong>#{@machineName or ''}</strong> #{stateTexts[@state]}"
    return "<span class='icon'></span>#{stateText}"


  createStateLabel: (customState)->

    @label     = new KDCustomHTMLView
      tagName  : 'p'
      partial  : customState or @getStateLabel()
      cssClass : "state-label #{@state.toLowerCase()}"

    @container.addSubView @label


  createStateButton: ->

    if @state in [Terminated, 'NotFound']
      title    = 'Create a new VM'
      callback = 'requestNewMachine'
    else if @isManaged
      title    = 'Search for Nodes'
      callback = 'findNodes'
    else
      title    = 'Turn it on'
      callback = 'turnOnMachine'

    @button    = new KDButtonView
      title    : title
      cssClass : 'turn-on state-button solid green medium'
      icon     : not @isManaged
      callback : @bound callback

    @container.addSubView @button


  createLoading: ->

    @loader?.destroy()
    @loader = new KDLoaderView
      showLoader : yes
      size       :
        width    : 40
        height   : 40

    @container.addSubView @loader


  createProgressBar: (initial = 10)->

    @progressBar = new KDProgressBarView { initial }

    @container.addSubView @progressBar


  createRetry: ->

    @retryView?.destroy()

    return  unless @progressBar?

    @container.addSubView @retryView = new KDCustomHTMLView
      cssClass : 'error-message warning'
      partial  : """
        <p>It's taking longer than expected, please reload the page.</p>
      """


  createFooter: ->

    return  unless @state is Stopped

    computeController = kd.getSingleton 'computeController'
    computeController.fetchUserPlan (plan)=>

      reason  = @machine.status.reason
      message = null

      if /^Stopped due inactivity/.test reason
        if plan is "free"
          message = "
            Your VM was automatically turned off after 60 minutes
            of inactivity as you are on the free plan."
          upgradeMessage = """
            <a href="/Pricing" class="upgrade-link">
              Upgrade to make your VMs always-on.
            </a>
          """
        else
          message = "
            Your VM was automatically turned off after 60 minutes
            of inactivity as it is not 'Always-on' enabled."
          upgradeMessage = """
            <a href="/Pricing" class="upgrade-link">
              Upgrade to get more always-on VMs.
            </a>
          """

      upgradeMessage = ""  if plan is "professional"

      return  unless message

      @addSubView @footer = new KDCustomHTMLView
        cssClass : 'footer'
        partial  : """
          <p>#{message}</p>
          #{upgradeMessage}
        """


  createError: ->

    return  unless @hasError

    sendDataDogEvent "MachineStateFailed"

    @errorMessage = new KDCustomHTMLView
      cssClass    : 'error-message'
      partial     : @customErrorMessage or """
        <p>There was an error when initializing your VM.</p>
        <span>Please try reloading this page or <span
        class="contact-support">contact support</span> for further
        assistance.</span>
      """
      click: (event) =>
        if 'contact-support' in event.target.classList
          kd.utils.stopDOMEvent event
          new HelpSupportModal

    @container.addSubView @errorMessage
    @hasError = null


  handleNoMachineFound: ->

    {@state} = @getOptions()
    @setClass 'no-machine'
    @buildViews()
    @createFooter()
    return @show()


  findNodes: ->
    {container} = @getOptions()

    FindManagedNodesModal = require './managed/findnodesmodal'
    findNodes = new FindManagedNodesModal { container }, @machine


  requestNewMachine: ->

    {container} = @getOptions()

    MoreVMsModal = require 'app/activity/sidebar/morevmsmodal'
    new MoreVMsModal { container }


  turnOnMachine: ->

    computeController = kd.getSingleton 'computeController'

    trackEvent 'Turn on machine, click',
      category : 'userInteraction'
      label    : 'turnedOnVM'
      action   : 'clicks'

    target     = @machine
    stack      = computeController.findStackFromMachineId @machine._id

    unless isKoding()
      if stack and @state is NotInitialized and \
         @machine.jMachine.generatedFrom?.templateId?
        action   = 'buildStack'
        target   = stack

    computeController.off  "error-#{target._id}"

    @emit 'MachineTurnOnStarted'

    methodName   = 'start'
    nextState    = 'Starting'

    if @state in [ NotInitialized, Terminated ]
      methodName = action ? 'build'
      nextState  = 'Building'

    computeController.once "error-#{target._id}", ({err})=>

      unless err?.code is ComputeController.Error.NotVerified
        @hasError = yes

      @buildViews State: @machine.status.state

    kd.singletons.computeController[methodName] target

    @state = nextState
    @buildViews()


  prepareIDE: ->

    {appManager, computeController} = kd.singletons

    # FIXME: We shouldn't use computeController.fetchMachine in this case.
    computeController.fetchMachines (err) =>

      return if showError err

      environmentDataProvider.fetchMachine @machine.uid, (machine) =>

        # return showError "Couldn't fetch your VMs"  unless machine
        unless machine
          return appManager.tell 'IDE', 'quit'

        @machine = machine
        @setData machine

        @emit 'IDEBecameReady', machine


  verifyAccount: ->

    code = Encoder.XSSEncode @codeEntryView.getValue()
    unless code then return new KDNotificationView
      title: "Please enter a code"

    remote.api.JUser.verifyByPin pin: code, (err)=>

      @pinIsValid?.destroy()

      if err
        @container.addSubView @pinIsValid = new KDCustomHTMLView
          cssClass : 'error-message'
          partial  : """
            <p>The pin entered is not valid.</p>
          """

      else
        kd.utils.defer @bound 'buildInitial'
        trackEvent 'Account verfication, success',
          category : 'userInteraction'
          action   : 'microConversions'
          label    : 'completedAccountVerification'


  downgradePlan: (callback)->

    me = whoami()
    me.fetchEmail (err, email)->

      kd.singletons.paymentController
        .subscribe "token", "free", "month", { email }, (err, resp)->
          return callback err  if err?
          callback null


  createMarketingMessage: ->

    return  if @container.hasClass 'marketing-message'

    { marketingController } = kd.singletons
    snippetUrl = marketingController.getNextSnippet()

    return  unless snippetUrl

    iframe       = new KDCustomHTMLView
      tagName    : 'iframe'
      cssClass   : "marketing-message-frame"
      attributes :
        src      : snippetUrl


    @container.addSubView iframe
    @container.setClass   'marketing-message'
