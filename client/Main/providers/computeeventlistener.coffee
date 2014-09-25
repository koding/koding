class ComputeEventListener extends KDObject

  constructor:(options = {})->

    super
      interval : options.interval ? 4000

    @kloud           = KD.singletons.kontrol.getKite
      name           : "kloud"
      environment    : KD.config.environment

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

    {computeController} = KD.singletons

    state = { status : event.status, reverted : event.reverted }
    state.percentage = event.percentage  if event.percentage?
    state.isSilent = !!event.silent

    unless state.isSilent
      @machineStatuses[machine.uid] = machine.status.state

    computeController.emit "public-#{machine._id}", state


  revertToPreviousState:(machine)->

    status   = @machineStatuses[machine.uid]
    reverted = status isnt machine.status.state
    @triggerState machine, { status, reverted }  if status?
    delete @machineStatuses[machine.uid]


  TypeStateMap =

    stop    : public : "MachineStopped",   private : Machine.State.Stopped
    start   : public : "MachineStarted",   private : Machine.State.Running
    build   : public : "MachineBuilt",     private : Machine.State.Running
    reinit  : public : "MachineBuilt",     private : Machine.State.Running
    destroy : public : "MachineDestroyed", private : Machine.State.Terminated


  tick:->

    return  unless @listeners.length
    return  if @tickInProgress
    @tickInProgress = yes

    {computeController} = KD.singletons

    @kloud.event @listeners

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

        log "#{res.event.eventId}", res.event

        if res.event.percentage is 100 and ev = TypeStateMap[type]
          computeController.emit ev.public, machineId: eventId
          computeController.emit "stateChanged-#{eventId}", ev.private
          computeController.stateChecker.watch eventId
          computeController.triggerReviveFor eventId

        unless res.event.status is 'Unknown'
          computeController.emit "public-#{eventId}",    res.event
          computeController.emit "#{res.event.eventId}", res.event

      @listeners = activeListeners
      @tickInProgress = no

    .catch (err)=>

      @tickInProgress = no

      warn "Eventer error:", err
      @stop()
