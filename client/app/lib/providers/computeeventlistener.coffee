kd = require 'kd'
KDObject = kd.Object
KodingKontrol = require '../kite/kodingkontrol'
Machine = require './machine'
globals = require 'globals'

module.exports = class ComputeEventListener extends KDObject

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
    @timer = kd.utils.repeat @getOption('interval'), @bound 'tick'


  stop:->

    return  unless @running
    @running = no
    kd.utils.killWait @timer


  uniqueAdd = (list, type, eventId)->

    for item in list
      return no  if item.type is type and item.eventId is eventId

    list.push { type, eventId }
    return yes


  addListener:(type, eventId)->

    {computeController} = kd.singletons

    if uniqueAdd @listeners, type, eventId

      @start()  unless @running
      computeController.stateChecker.ignore eventId


  triggerState:(machine, event)->

    return  unless machine?
    return  if machine.provider is 'managed' and \
               event.status not in [Running, Stopped]

    {computeController, kontrol} = kd.singletons

    state = { status : event.status, reverted : event.reverted }
    state.percentage = event.percentage  if event.percentage?
    state.isSilent = !!event.silent

    unless state.isSilent
      @machineStatuses[machine.uid] = machine.status.state

    computeController.emit "public-#{machine._id}", state

    unless event.status is Running
      computeController.invalidateCache machine._id


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

    {computeController} = kd.singletons

    computeController.getKloud().event @listeners

    .then (responses)=>

      activeListeners = []
      responses.forEach (res)=>

        if res.err? and not res.event?
          kd.warn "Error on '#{res.event_id}':", res.err
          computeController.stateChecker.watch res.event_id

          # TODO We need to think about this again ~ GG
          # What will happen next?

          return

        [type, eventId] = res.event.eventId.split '-'

        if res.event.percentage < 100 and \
           res.event.status isnt Machine.State.Unknown
          uniqueAdd activeListeners, type, eventId

        kd.info "#{res.event.eventId}", res.event

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

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err)=>

      @tick yes  if err.name is "TimeoutError"

      kd.warn "Eventer error:", err
      @stop()


  followUpcomingEvents: (machine, followOthers = no)->

    StateEventMap =

      Stopping    : "stop"
      Building    : "build"
      Starting    : "start"
      Rebooting   : "restart"
      Terminating : "destroy"
      Pending     : "resize"

    stateEvent = StateEventMap[machine.status.state]

    if stateEvent

      @addListener stateEvent, machine._id

      if stateEvent in ["build", "destroy"] and followOthers
        @addListener "reinit", machine._id

      return yes

    return no
