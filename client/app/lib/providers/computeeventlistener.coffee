kd       = require 'kd'
globals  = require 'globals'
Tracker  = require 'app/util/tracker'
getGroup = require 'app/util/getGroup'
sendDataDogEvent = require 'app/util/sendDataDogEvent'


module.exports = class ComputeEventListener extends kd.Object


  constructor: (options = {}) ->

    super
      interval : options.interval ? 4000

    @listeners       = []
    @machineStatuses = {}
    @tickInProgress  = no
    @running         = no
    @timer           = null


  start: ->

    return  if @running
    @running = yes

    @tick()
    @timer = kd.utils.repeat @getOption('interval'), @bound 'tick'


  stop: ->

    return  unless @running
    @running = no
    kd.utils.killWait @timer


  uniqueAdd = (list, type, eventId) ->

    for item in list
      return no  if item.type is type and item.eventId is eventId

    list.push { type, eventId }
    return yes


  addListener: (type, eventId) ->

    { computeController } = kd.singletons

    if uniqueAdd @listeners, type, eventId

      @start()  unless @running
      computeController.stateChecker.ignore eventId


  triggerState: (machine, event) ->

    return  unless machine?
    return  if machine.provider is 'managed' and \
               event.status not in ['Running', 'Stopped']

    { computeController, kontrol } = kd.singletons

    state = { status : event.status, reverted : event.reverted }
    state.percentage = event.percentage  if event.percentage?
    state.isSilent = !!event.silent

    unless state.isSilent
      @machineStatuses[machine.uid] = machine.status.state

    computeController.emit "public-#{machine._id}", state

    unless event.status is 'Running'
      computeController.invalidateCache machine._id


  revertToPreviousState: (machine) ->

    status   = @machineStatuses[machine.uid]
    reverted = status isnt machine.status.state
    @triggerState machine, { status, reverted }  if status?
    delete @machineStatuses[machine.uid]


  TypeStateMap     =
    stop           :
      public       : 'MachineStopped'
      private      : 'Stopped'
    start          :
      public       : 'MachineStarted'
      private      : 'Running'
    build          :
      public       : 'MachineBuilt'
      private      : 'Running'
    destroy        :
      public       : 'MachineDestroyed'
      private      : 'Terminated'
    apply          :
      public       : 'MachineBuilt'
      private      : 'Running'


  tick: (force) ->

    return  unless @listeners.length
    return  if not force and @tickInProgress
    @tickInProgress = yes

    { computeController } = kd.singletons

    computeController.getKloud().event @listeners

    .then (responses) =>

      activeListeners = []
      responses.forEach (res) ->

        if res.err? and not res.event?

          kd.warn "Error on '#{res.event_id}':", res
          computeController.stateChecker.watch res.event_id

          # TODO We need to think about this again ~ GG
          # What will happen next?

          return

        { event } = res
        [type, eventId] = event.eventId.split '-'

        if type is 'migrate'
          [type, groupName, eventId] = event.eventId.split '-'
          type = "#{type}-#{groupName}"
          computeController.emit type, event

        if event.percentage < 100 and \
           event.status isnt 'Unknown'
          uniqueAdd activeListeners, type, eventId

        kd.info "#{event.eventId}", event

        isMyStack = computeController.findStackFromStackId(eventId)?
        if not event.error and event.percentage is 100 and ev = TypeStateMap[type]
          computeController.emit ev.public, { machineId: eventId }
          computeController.emit "stateChanged-#{eventId}", ev.private
          computeController.stateChecker.watch eventId
          # Perform tracker only if stack is mine.
          # It avoids tracking when admin listens to member's stack process
          if isMyStack and type is 'apply'
            Tracker.track Tracker.STACKS_BUILD_SUCCESSFULLY, {
              customEvent :
                stackId   : eventId
                group     : getGroup().slug
            }
          Tracker.track Tracker.VM_TURNED_OFF if event.status is 'Stopped'
          # For `apply` event revive all the machines in a stack ~ GG
          computeController.triggerReviveFor eventId, type is 'apply'
        else if event.error and event.percentage is 100 and type is 'apply'
          if isMyStack
            sendDataDogEvent 'StackBuildFailed', { prefix: 'stack-build' }
            Tracker.track Tracker.STACKS_BUILD_FAILED, {
              customEvent :
                stackId   : eventId
                group     : getGroup().slug
            }
          # If a stack `apply` is failed we need to revive it from DB ~ GG
          computeController.triggerReviveFor eventId, yes
        else
          computeController.stateChecker.ignore eventId

        unless event.status is 'Unknown'
          computeController.emit "public-#{eventId}", event
          computeController.emit "#{event.eventId}",  event

      @listeners = activeListeners
      @tickInProgress = no

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      @tick yes  if err.name is 'TimeoutError'

      kd.warn 'Eventer error:', err
      @stop()


  followUpcomingEvents: (machine, followOthers = no) ->

    StateEventMap =

      Stopping    : 'stop'
      Building    : 'build'
      Starting    : 'start'
      Rebooting   : 'restart'
      Terminating : 'destroy'

    stateEvent = StateEventMap[machine.status.state]

    if stateEvent
      @addListener stateEvent, machine._id
      return yes

    return no
