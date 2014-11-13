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

    @buildInitial()

    computeController = KD.getSingleton 'computeController'

    computeController.on "start-#{@machineId}", @bound 'updateStatus'
    computeController.on "build-#{@machineId}", @bound 'updateStatus'
    computeController.on "stop-#{@machineId}",  @bound 'updateStatus'

    computeController.on "reinit-#{@machineId}",(event)=>
      @updateStatus event, 'reinit'

    computeController.on "resize-#{@machineId}",(event)=>
      @updateStatus event, 'resize'

    @show()

    computeController.followUpcomingEvents @machine

    @eventTimer = null
    @_lastPercentage = 0


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

    {status, percentage, error} = event

    if status is @state

      if percentage?

        @triggerEventTimer percentage

        @progressBar?.updateBar Math.max percentage, 10
        @progressBar?.show()

    else

      @state = status
      @hasError = error?.length > 0

      if percentage?

        if percentage is 100

          @clearEventTimer()

          if status is Running
            @prepareIDE()
            @destroy()

          else
            @progressBar?.updateBar 100
            @progressBar?.show()

            KD.utils.wait 500, => @buildViews()

        else if task is 'reinit'

          @progressBar?.updateBar Math.max percentage, 10
          @progressBar?.show()
          @label?.updatePartial @getStateLabel()

          @triggerEventTimer percentage

        else

          @clearEventTimer()
          @buildViews()

      else

        if status is Running
          @prepareIDE()
          @destroy()


  buildInitial:->

    @container.destroySubViews()

    @createStateLabel "Checking state for <strong>#{@machineName or ''}</strong>..."
    @createLoading()
    @createFooter()

    if @getOption 'initial'

      currentState = @machine.status.state

      if currentState is NotInitialized
        @buildViews State: currentState
        return

      KD.getSingleton 'computeController'
        .kloud.info { @machineId, currentState }
        .then (response)=>

          info "Initial info result:", response

          @buildViews response

          if response.State is NotInitialized
            KD.utils.defer => @turnOnMachine()

        .catch (err)=>

          warn "Failed to fetch initial info:", err
          @hasError = yes
          @buildViews()

    else
      @buildViews()


  buildViews: (response)->

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

      if @machine.status.state is Terminated
        KD.getSingleton 'computeController'
          .kloud.info { @machineId, currentState: @machine.status.state }
          .then (response)=>
            if response.State is Terminated
              @createStateButton()
          .catch noop
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
            of inactivity as you are in <strong>Free</strong> plan."
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
      partial     : """
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


  turnOnMachine: ->

    computeController = KD.getSingleton 'computeController'
    computeController.off  "error-#{@machineId}"

    @emit 'MachineTurnOnStarted'

    methodName   = 'start'
    nextState    = 'Starting'

    if @state in [ NotInitialized, Terminated ]
      methodName = 'build'
      nextState  = 'Building'

    computeController.once "error-#{@machineId}", (err)=>
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


  handleNoMachineFound: ->

    {@state} = @getOptions()
    @setClass 'no-machine'
    @buildViews()
    @createFooter()
    return @show()
