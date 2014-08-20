class IDE.MachineStateModal extends IDE.ModalView

  constructor: (options = {}, data) ->

    options.cssClass or= 'ide-machine-state'
    options.width      = 440
    options.height     = 270

    super options, data

    @addSubView @container = new KDCustomHTMLView cssClass: 'content-container'

    unless data
      @state = options.state
      return @buildViews()

    {jMachine}   = data
    @machineName = jMachine.label
    @machineId   = jMachine._id
    {@state}     = data.status

    @buildViews()

    KD.getSingleton('computeController').on "start-#{@machineId}", (event) =>
      {status} = event
      return if status is @state

      @state = status
      @buildViews()

    KD.getSingleton('computeController').on "build-#{@machineId}", (event) =>
      {status} = event
      return if status is @state

      @state = status
      @buildViews()

    @show()

  buildViews: ->
    @container.destroySubViews()

    @createStateLabel()

    if @state in ['Stopped', 'Running', 'NotInitialized', 'Terminated']
      @createStateButton()
    else if @state in [ 'Starting', 'Building', 'Stopping' ]
      @createLoading()

    @createFooter()  unless @footer

  createStateLabel: ->
    stateTexts       =
      Stopped        : 'is turned off.'
      Starting       : 'is starting now.'
      Stopping       : 'is stopping now.'
      Running        : 'up and running.'
      Building       : 'is building now.'
      NotInitialized : 'is turned off.'
      Terminated     : 'is turned off.'
      NotFound       : 'This machine does not exist.' # additional class level state to show a modal for unknown routes.

    @label     = new KDCustomHTMLView
      tagName  : 'p'
      partial  : "<span class='icon'></span><strong>#{@machineName or ''}</strong> #{stateTexts[@state]}"
      cssClass : "state-label #{@state.toLowerCase()}"

    @container.addSubView @label

  createStateButton: ->
    @button      = new KDButtonView
      title      : 'Turn it on'
      cssClass   : 'turn-on state-button solid green medium'
      icon       : yes
      callback   : @bound 'turnOnMachine'

    if @state is 'Running'
      @button    = new KDButtonView
        title    : 'Start IDE'
        cssClass : 'start-ide state-button solid green medium'
        callback : @bound 'startIDE'

    @container.addSubView @button

  createLoading: ->
    @loader = new KDLoaderView
      showLoader : yes
      size       :
        width    : 44
        height   : 44

    @container.addSubView @loader

  createFooter: ->
    @footer    = new KDCustomHTMLView
      cssClass : 'footer'
      partial  : """
        <p>Free account VMs are shutdown when you leave Koding.</p>
        <a href="#" class="upgrade-link">Upgrade your account to keep it always on</a>
        <a href="#" class="info-link">More about VMs</a>
        <span class="more-icon"></span>
      """

    @addSubView @footer

  turnOnMachine: ->
    methodName   = 'start'
    nextState    = 'Starting'

    if @state is 'NotInitialized'
      methodName = 'build'
      nextState  = 'Building'

    KD.getSingleton('computeController')[methodName] @getData()
    @state = nextState
    @buildViews()

  startIDE: ->
    @destroy()

    KD.getSingleton('computeController').fetchMachines (err, machines) =>
      return KD.showError "Couldn't fetch your VMs"  if err

      m = machine for machine in machines when machine._id is @getData()._id

      KD.getSingleton('appManager').tell 'IDE', 'mountMachine', m
      @setData m
