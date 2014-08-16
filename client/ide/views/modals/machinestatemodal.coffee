class IDE.MachineStateModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass or= 'ide-machine-state'
    options.overlay    = yes

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

  buildViews: ->
    @container.destroySubViews()

    @createStateLabel()

    if @state in ['Stopped', 'Running', 'NotInitialized']
      @createStateButton()
    else if @state in [ 'Starting', 'Building' ]
      @createLoading()

    @createFooter()  unless @footer

  createStateLabel: ->
    stateTexts       =
      Stopped        : 'is turned off.'
      Starting       : 'is starting now.'
      Stopping       : 'is stopping now.'
      Running        : 'up and running.'
      Building       : 'is building now.'
      NotInitialized : 'is not initialized.'
      NotFound       : 'This machine is not exist.' # additional class level state to show a fancy modal for route hacking.

    @label     = new KDCustomHTMLView
      tagName  : 'p'
      partial  : "<span class='icon'></span><strong>#{@machineName or ''}</strong> #{stateTexts[@state]}"
      cssClass : "state-label #{@state.toLowerCase()}"

    @container.addSubView @label

  createStateButton: ->
    @button      = new KDButtonView
      title      : 'Turn it on'
      cssClass   : 'turn-on state-button solid green medium'
      callback   : @bound 'turnOnMachine'

    if @state is 'Running'
      @button    = new KDButtonView
        title    : 'Start IDE'
        cssClass : 'start-ide state-button solid green medium'
        callback : @bound 'startIDE'

    else if @state is 'NotInitialized'
      @button    = new KDButtonView
        title    : 'Initialize Machine'
        cssClass : 'intialize state-button solid green medium'
        callback : @bound 'initalizeMachine'

    @container.addSubView @button

  createLoading: ->
    @loader = new KDLoaderView
      showLoader : yes
      size       :
        width    : 48
        height   : 48

    @container.addSubView @loader

  createFooter: ->
    @footer    = new KDCustomHTMLView
      cssClass : 'footer'
      partial  : """
        <p>Free account VMs are shutdown when you leave Koding.</p>
        <a href="#" class="upgrade-link">Upgrade your account to keep it always on</a>
        <a href="#" class="info-link">
          More about VMs <span class="more-icon"></span>
        </a>
      """

    @addSubView @footer

  turnOnMachine: ->
    KD.getSingleton('computeController').start @getData()

  initalizeMachine: ->
    KD.getSingleton('computeController').build @getData()

  startIDE: -> @destroy()
