class ComputeEventListener extends KDObject

  {Stopped, Running, Terminated} = Machine.State

  constructor:(options = {})->

    super
      interval : options.interval ? 4000

    @listeners       = []
    @machineStatuses = {}
    @tickInProgress  = no
    @running         = no
    @timer           = null


  start:->

    return  if @running
    @running = yes

    @tick()
    @timer = KD.utils.repeat @getOption('interval'), @bound 'tick'


  stop:->

    return  unless @running
    @running = no
    KD.utils.killWait @timer


  uniqueAdd = (list, type, eventId)->

    for item in list
      return no  if item.type is type and item.eventId is eventId

    list.push { type, eventId }
    return yes


  addListener:(type, eventId)->

    {computeController} = KD.singletons

    if uniqueAdd @listeners, type, eventId

      @start()  unless @running
      computeController.stateChecker.ignore eventId


  triggerState:(machine, event)->

    return  unless machine?

    {computeController} = KD.singletons

    state = { status : event.status, reverted : event.reverted }
    state.percentage = event.percentage  if event.percentage?
    state.isSilent = !!event.silent

    unless state.isSilent
      @machineStatuses[machine.uid] = machine.status.state

    computeController.emit "public-#{machine._id}", state

    unless event.status is Running
      computeController.invalidateCache machine._id

      KodingKontrol.dcNotification?.destroy()
      KodingKontrol.dcNotification = null


  revertToPreviousState:(machine)->

    status   = @machineStatuses[machine.uid]
    reverted = status isnt machine.status.state
    @triggerState machine, { status, reverted }  if status?
    delete @machineStatuses[machine.uid]


  TypeStateMap =

    stop    : public : "MachineStopped",   private : Stopped
    start   : public : "MachineStarted",   private : Running
    build   : public : "MachineBuilt",     private : Running
    reinit  : public : "MachineBuilt",     private : Running
    resize  : public : "MachineResized",   private : Running
    destroy : public : "MachineDestroyed", private : Terminated


  tick: (force)->

    return  unless @listeners.length
    return  if not force and @tickInProgress
    @tickInProgress = yes

    {computeController} = KD.singletons

    computeController.getKloud().event @listeners

    .then (responses)=>

      activeListeners = []
      responses.forEach (res)=>

        if res.err? and not res.event?
          warn "Error on '#{res.event_id}':", res.err
          computeController.stateChecker.watch res.event_id
          return

        [type, eventId] = res.event.eventId.split '-'

        if res.event.percentage < 100 and \
           res.event.status isnt Machine.State.Unknown
          uniqueAdd activeListeners, type, eventId

        info "#{res.event.eventId}", res.event

        if res.event.percentage is 100 and ev = TypeStateMap[type]
          computeController.emit ev.public, machineId: eventId
          computeController.emit "stateChanged-#{eventId}", ev.private
          computeController.stateChecker.watch eventId
          computeController.triggerReviveFor eventId
        else
          computeController.stateChecker.ignore eventId

        unless res.event.status is 'Unknown'
          computeController.emit "public-#{eventId}",    res.event
          computeController.emit "#{res.event.eventId}", res.event

      @listeners = activeListeners
      @tickInProgress = no

    .timeout ComputeController.timeout

    .catch (err)=>

      @tick yes  if err.name is "TimeoutError"

      warn "Eventer error:", err
      @stop()
