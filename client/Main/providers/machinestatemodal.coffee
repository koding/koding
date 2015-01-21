class EnvironmentsMachineStateModal extends EnvironmentsModalView

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

    @showBusy()
    @show()

    KD.whoami().isEmailVerified (err, verified)=>

      warn err  if err?

      if not verified
      then @buildVerifyView()
      else
        KD.singletons.paymentController.subscriptions (err, subscription)=>
          warn err  if err?
          if subscription?.state is 'expired'
          then @buildExpiredView subscription
          else @buildInitial()


  triggerEventTimer: (percentage)->

    if percentage isnt @_lastPercentage
      clearTimeout @eventTimer
    else unless @eventTimer
      @eventTimer = KD.utils.wait EVENT_TIMEOUT, @bound 'createRetry'

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

      if error?.length > 0

        if /NetworkOut overlimit/i.test event.message
          @customErrorMessage = """
            <p>You've reached your outbound network usage limit for this week.</p>
            <span>Please upgrade your <a href="/Pricing">plan</a> or <span
            class="contact-support">contact support</span> for further
            assistance.</span>
          """

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

    KD.utils.wait 500, => @buildViews()


  showBusy: (message) ->

    @_busy = message?

    @container.destroySubViews()

    @createStateLabel message ? "Loading..."
    @createLoading()


  buildInitial:->

    return @buildViews()  if @_initialBuiltOnce

    computeController = KD.getSingleton 'computeController'

    computeController.on "start-#{@machineId}", @bound 'updateStatus'
    computeController.on "build-#{@machineId}", @bound 'updateStatus'
    computeController.on "stop-#{@machineId}",  @bound 'updateStatus'

    computeController.on "reinit-#{@machineId}",(event)=>
      @updateStatus event, 'reinit'

    computeController.on "resize-#{@machineId}",(event)=>
      @updateStatus event, 'resize'

    computeController.followUpcomingEvents @machine

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

      KD.getSingleton 'computeController'
        .getKloud().info { @machineId, currentState }
        .then (response)=>

          info "Initial info result:", response

          @buildViews response

        .catch (err)=>

          unless err?.code is ComputeController.Error.NotVerified
            warn "Failed to fetch initial info:", err
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
      partial  : """
        <p>Before you can access your VM, we need to verify your account.
        A verification email should already be in your inbox.
        If you did not receive it yet, you can request a <cite>new code</cite>.</p>
      """
      click    : (event)=>

        return  unless $(event.target).is 'cite'

        KD.remote.api.JUser.verifyByPin resendIfExists: yes, (err)=>

          unless KD.showError err

            @container.addSubView @retryView = new KDCustomHTMLView
              cssClass : 'error-message warning'
              partial  : """
                <p>Email sent, please check your inbox.</p>
              """

            KD.utils.wait 3000, @retryView.bound 'destroy'

    @container.addSubView @codeEntryView
    @container.addSubView @button


  buildExpiredView: (subscription, nextState)->

    plan = if subscription? then "(<b>#{subscription.planTitle}</b>)" else ""

    @container.destroySubViews()

    if nextState is "downgrade"

      @showBusy "Downgrading..."
      @downgradePlan (err)=>

        if err?
          KD.utils.wait 10000, =>
            @buildExpiredView subscription, "downgrade"
        else
          ComputeHelpers.handleNewMachineRequest (err)=>
            location.reload yes

      return

    destroyVMs = nextState is "destroy-vms"

    @upgradeButton = new KDButtonView
      title    : 'Upgrade Plan'
      cssClass : 'solid green medium plan-change-button'
      callback : -> KD.singletons.router.handleRoute '/Pricing'

    actionTitle = if destroyVMs then 'Delete All VMs' else 'Downgrade Plan'

    @actionButton = new KDButtonView
      title    : actionTitle
      cssClass : 'solid green medium plan-change-button downgrade'
      callback : =>

        if destroyVMs

          @showBusy "Destroying machines..."
          ComputeHelpers.destroyExistingMachines (err)=>
            KD.utils.wait 5000, =>
              @buildExpiredView subscription, "downgrade"

        else

          @showBusy "Downgrading..."
          @downgradePlan (err)=> if err? \
            then @buildExpiredView subscription, "destroy-vms"
            else @buildInitial()

    @container.addSubView new KDCustomHTMLView
      cssClass : 'expired-message'
      partial  : if destroyVMs then """
        <h1>Delete all existing VMs</h1>
        <p>To be able to downgrade your current plan #{plan} to the <b>Free</b>
        plan, you need to delete all your existing VMs. This action will
        <b>destroy all your VMs, (including YOUR FILES) and cannot
        be UNDONE!</b> Are you sure you want to continue?</p>
      """ else """
        <h1>Plan Expired</h1>
        <p>Your current plan #{plan} is expired. For accessing
        your VM you need to upgrade your plan first. Or you can downgrade
        to the <b>Free</b> plan which will <b>destroy</b> all your existing VMs and their
        files.</p>
      """

    unless destroyVMs
      @container.addSubView @upgradeButton

    @container.addSubView @actionButton


  buildViews: (response)->

    return  if @_busy

    if response?.State?
      @state = response.State

    @container.destroySubViews()
    @progressBar = null

    @createStateLabel()

    if @state in [ Stopped, NotInitialized, Unknown ]
      @createStateButton()
    else if @state in [ Starting, Building, Pending, Stopping, Terminating, Updating, Rebooting ]
      percentage = response?.percentage
      @createProgressBar percentage
      @triggerEventTimer percentage
    else if @state is Terminated
      @label.destroy?()

      @createStateLabel """
        Your VM <strong>#{@machineName or ''}</strong> was successfully deleted.
        Please select a new VM to operate on from the VMs list or create a new one.
      """
    else if @state is Running
      @prepareIDE()
      @destroy()

    @createError()



  getStateLabel:->

    stateTexts       =
      Stopped        : 'is turned off.'
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
      NotFound       : 'This machine does not exist.' # additional class level state to show a modal for unknown routes.

    stateText = "<strong>#{@machineName or ''}</strong> #{stateTexts[@state]}"
    return "<span class='icon'></span>#{stateText}"


  createStateLabel: (customState)->

    @label     = new KDCustomHTMLView
      tagName  : 'p'
      partial  : customState or @getStateLabel()
      cssClass : "state-label #{@state.toLowerCase()}"

    @container.addSubView @label


  createStateButton: ->

    @button      = new KDButtonView
      title      : 'Turn it on'
      cssClass   : 'turn-on state-button solid green medium'
      icon       : yes
      callback   : @bound 'turnOnMachine'

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

    computeController = KD.getSingleton 'computeController'
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

    KD.utils.sendDataDogEvent "MachineStateFailed"

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
          KD.utils.stopDOMEvent event
          new HelpSupportModal

    @container.addSubView @errorMessage
    @hasError = null


  handleNoMachineFound: ->

    {@state} = @getOptions()
    @setClass 'no-machine'
    @buildViews()
    @createFooter()
    return @show()


  turnOnMachine: ->

    computeController = KD.getSingleton 'computeController'
    computeController.off  "error-#{@machineId}"

    @emit 'MachineTurnOnStarted'

    methodName   = 'start'
    nextState    = 'Starting'

    if @state in [ NotInitialized, Terminated ]
      methodName = 'build'
      nextState  = 'Building'

    computeController.once "error-#{@machineId}", ({err})=>

      unless err?.code is ComputeController.Error.NotVerified
        @hasError = yes

      @buildViews State: @machine.status.state

    KD.singletons.computeController[methodName] @machine

    @state = nextState
    @buildViews()


  prepareIDE: ->

    KD.getSingleton('computeController').fetchMachines (err, machines) =>
      return KD.showError "Couldn't fetch your VMs"  if err

      m = machine for machine in machines when machine._id is @machine._id

      KD.getSingleton('appManager').tell 'IDE', 'mountMachine', m
      @machine = m
      @setData m

      @emit 'IDEBecameReady', m


  verifyAccount: ->

    code = Encoder.XSSEncode @codeEntryView.getValue()
    unless code then return new KDNotificationView
      title: "Please enter a code"

    KD.remote.api.JUser.verifyByPin pin: code, (err)=>

      @pinIsValid?.destroy()

      if err
        @container.addSubView @pinIsValid = new KDCustomHTMLView
          cssClass : 'error-message'
          partial  : """
            <p>The pin entered is not valid.</p>
          """

      else
        KD.utils.defer @bound 'buildInitial'


  downgradePlan: (callback)->

    me = KD.whoami()
    me.fetchEmail (err, email)->

      KD.singletons.paymentController
        .subscribe "token", "free", "month", { email }, (err, resp)->
          return callback err  if err?
          callback null
