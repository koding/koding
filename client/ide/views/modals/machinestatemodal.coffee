class IDE.MachineStateModal extends IDE.ModalView

  {
    Stopped, Running, NotInitialized, Terminated, Unknown,
    Starting, Building, Stopping, Rebooting, Terminating, Updating
  } = Machine.State

  constructor: (options = {}, data) ->

    options.cssClass or= 'ide-machine-state'
    options.width      = 440
    # options.height   = 270

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
    computeController.on "error-#{@machineId}", =>
      @hasError = yes
      @updateStatus { status: Unknown }

    @show()


  updateStatus: (event) ->

    {status, percentage} = event

    if status is @state
      if percentage?
        @progressBar?.updateBar Math.max percentage, 10
        @progressBar?.show()

    else
      @state = status

      if percentage? and percentage is 100
        @progressBar?.updateBar 100
        @progressBar?.show()

        KD.utils.wait 500, => @buildViews()

      else
        @buildViews()

      if status is Running
        @prepareIDE()
        @destroy()


  buildInitial:->

    @container.destroySubViews()

    @createStateLabel "Checking state for <strong>#{@machineName or ''}</strong>..."
    @createLoading()
    @createFooter()

    if @getOption 'initial'
      KD.getSingleton 'computeController'
        .kloud.info { @machineId }
        .then (response)=>

          @buildViews response

          if response.State is NotInitialized
            KD.utils.defer => @turnOnMachine()

        .catch => @buildViews()
    else
      @buildViews()


  buildViews: (response)->

    if response?.State?
      @state = response.State

    @container.destroySubViews()

    @createStateLabel()

    if @state in [ Stopped, Running, NotInitialized, Terminated, Unknown ]
      @createStateButton()
    else if @state in [ Starting, Building, Stopping, Terminating, Updating, Rebooting ]
      @createProgressBar()

    @createError()


  createStateLabel: (customState)->

    stateTexts       =
      Stopped        : 'is turned off.'
      Starting       : 'is starting now.'
      Stopping       : 'is stopping now.'
      Running        : 'up and running.'
      Building       : 'is building now.'
      NotInitialized : 'is turned off.'
      Terminated     : 'is turned off.'
      Rebooting      : 'is rebooting.'
      Terminating    : 'is terminating.'
      Updating       : 'is updating now.'
      Unknown        : 'is turned off.'
      NotFound       : 'This machine does not exist.' # additional class level state to show a modal for unknown routes.

    stateText = customState or "<strong>#{@machineName or ''}</strong> #{stateTexts[@state]}"

    @label     = new KDCustomHTMLView
      tagName  : 'p'
      partial  : "<span class='icon'></span>#{stateText}"
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


  createProgressBar: ->

    @progressBar = new KDProgressBarView
      initial    : 10

    @container.addSubView @progressBar


  createFooter: ->

    @footer    = new KDCustomHTMLView
      cssClass : 'footer'
      partial  : """
        <p>Free account VMs are turned off automatically after 60 minutes of inactivity.</p>
        <a href="/Pricing" class="upgrade-link">Upgrade to make your VMs always-on.</a>
      """

    @addSubView @footer


  createError: ->

    return  unless @hasError

    @errorMessage = new KDCustomHTMLView
      cssClass    : 'error-message'
      partial     : """
        <p>There was an error with your VM. Please try again.</p>
        <p>Contact support@koding.com for further assistance.</p>
      """

    @container.addSubView @errorMessage
    @hasError = null


  turnOnMachine: ->

    @emit 'MachineTurnOnStarted'

    methodName   = 'start'
    nextState    = 'Starting'

    if @state in [ NotInitialized, Terminated, Unknown ]
      methodName = 'build'
      nextState  = 'Building'

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
