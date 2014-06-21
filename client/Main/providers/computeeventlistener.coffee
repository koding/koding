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


  addListener:(type, eventId)->

    inList = no
    @listeners.forEach (_)->
      inList |= _.type is type and _.eventId is eventId

    unless inList
      @listeners.push { type, eventId }
      @start()  unless @running


  triggerState:(machine, event)->

    {computeController} = KD.singletons

    state = { status : event.status, reverted : event.reverted }
    state.percentage = event.percentage  if event.percentage?

    @machineStatuses[machine.uid] = machine.status.state

    computeController.emit "public-#{machine._id}", state


  revertToPreviousState:(machine)->

    status   = @machineStatuses[machine.uid]
    reverted = status isnt machine.status.state
    @triggerState machine, { status, reverted }  if status?
    delete @machineStatuses[machine.uid]


  tick:->

    return  unless @listeners.length
    return  if @tickInProgress
    @tickInProgress = yes

    {computeController} = KD.singletons
    @kloud.event @listeners

    .then (responses)=>

      activeListeners = []
      responses.forEach (res)=>

        if res.err
          warn "Error on '#{res.event_id}':", res.err

        else

          [type, eventId] = res.event.eventId.split '-'

          if res.event.percentage < 100
            activeListeners.push { type, eventId }

          log "#{res.event.eventId}", res.event

          if res.event.percentage is 100 and type is "build"
            computeController.emit "machineBuildCompleted", machineId: eventId

          unless res.event.status is 'Unknown'
            computeController.emit "public-#{eventId}", res.event
            computeController.emit "#{res.event.eventId}", res.event

      @listeners = activeListeners
      @tickInProgress = no

    .catch (err)=>

      @tickInProgress = no
      warn "Eventer error:", err
      @stop()
