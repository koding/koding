class ComputeController extends KDController

  @providers = KD.config.providers

  @timeout = 5000

  constructor:->
    super

    { mainController, kontrol } = KD.singletons

    do @reset

    mainController.ready =>

      @kloud         = kontrol.getKite
        name         : "kloud"
        environment  : KD.config.environment

      @eventListener = new ComputeEventListener

      @on "MachineBuilt",   => do @reset
      @on "MachineDestroy", => do @reset

      @fetchStacks =>

        if @stacks.length is 0 then do @createDefaultStack

        @storage = KD.singletons.appStorageController.storage 'Compute', '0.0.1'
        @emit 'ready'

        @info machine for machine in @machines


  fetchStacks: do (queue=[])->

    (callback = noop)-> KD.singletons.mainController.ready =>

      if @stacks.length > 0
        callback null, @stacks
        info "Stacks returned from cache."
        return

      return  if (queue.push callback) > 1

      KD.remote.api.JStack.some {}, (err, stacks = [])=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        if stacks.length > 0

          machines = []
          stacks.forEach (stack)->
            stack.machines.forEach (machine, index)->
              machine = new Machine { machine }
              stack.machines[index] = machine
              machines.push machine

          @machines = machines
          @stacks   = stacks
          cb null, stacks  for cb in queue

        else
          cb null, []  for cb in queue

        queue = []


  fetchMachines: do (queue=[])->

    (callback = noop)-> KD.singletons.mainController.ready =>

      if @machines
        callback null, @machines
        info "Machines returned from cache."
        return

      return  if (queue.push callback) > 1

      @fetchStacks (err, stacks)=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        machines = []
        stacks.forEach (stack)->
          stack.machines.forEach (machine)->
            machines.push machine

        @machines = machines
        cb null, machines  for cb in queue
        queue = []


  fetchMachine: (idOrUid, callback = noop)->

    KD.remote.api.JMachine.one idOrUid, (err, machine)->
      if KD.showError err then callback err
      else if machine? then callback null, new Machine { machine }


  queryMachines: (query = {}, callback = noop)->

    KD.remote.api.JMachine.some query, (err, machines)=>
      if KD.showError err then callback err
      else callback null, (new Machine { machine } for machine in machines)


  credentialsFor: (provider, callback)->
    KD.remote.api.JCredential.some { provider }, callback

  fetchAvailable: (options, callback)->
    KD.remote.api.ComputeProvider.fetchAvailable options, callback

  fetchExisting: (options, callback)->
    KD.remote.api.ComputeProvider.fetchExisting options, callback

  create: (options, callback)->
    KD.remote.api.ComputeProvider.create options, callback

  createDefaultStack: ->

    KD.remote.api.ComputeProvider.createGroupStack (err, stack)=>
      return if KD.showError err
      @reset yes


  reset: (render = no)->

    @stacks   = []
    @machines = []

    if render then @fetchStacks =>
      @info machine for machine in @machines
      @emit "renderStacks"


  errorHandler = (task, eL, machine)-> (err)->

    eL.revertToPreviousState machine
    warn "info err:", err


  destroy: (machine)->

    ComputeController.UI.askFor 'destroy', machine, =>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      @kloud.destroy { machineId: machine._id }

      .timeout ComputeController.timeout

      .then (res)=>

        @eventListener.addListener 'destroy', machine._id
        log "destroy res:", res

      .catch errorHandler 'destroy', @eventListener, machine


  build: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Building
      percentage  : 0

    machine.getBaseKite().disconnect()

    @kloud.build { machineId: machine._id }

    .timeout ComputeController.timeout

    .then (res)=>

      @eventListener.addListener 'build', machine._id
      log "build res:", res

    .catch errorHandler 'build', @eventListener, machine


  start: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Starting
      percentage  : 0

    @kloud.start { machineId: machine._id }

    .timeout ComputeController.timeout

    .then (res)=>

      @eventListener.addListener 'start', machine._id
      log "start res:", res

    .catch errorHandler 'start', @eventListener, machine


  stop: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Stopping
      percentage  : 0

    machine.getBaseKite( createIfExists = no ).disconnect()

    @kloud.stop { machineId: machine._id }

    .timeout ComputeController.timeout

    .then (res)=>

      @eventListener.addListener 'stop', machine._id
      log "stop res:", res

    .catch errorHandler 'stop', @eventListener, machine


  StateEventMap =

    Stopping    : "stop"
    Building    : "build"
    Starting    : "start"
    Rebooting   : "restart"
    Terminating : "destroy"

  info: (machine)->

    stateEvent = StateEventMap[machine.status.state]

    if stateEvent
      @eventListener.addListener stateEvent, machine._id
      return Promise.resolve()

    @eventListener.triggerState machine,
      status      : machine.status.state
      percentage  : 0

    @kloud.info { machineId: machine._id }

    .timeout ComputeController.timeout

    .then (response)=>

      log "info response:", response
      @eventListener.triggerState machine,
        status      : response.state
        percentage  : 100

    .catch errorHandler 'info', @eventListener, machine


  requireMachine: (options = {}, callback = noop)-> @ready =>

    {app} = options
    unless app?.name?
      warn message = "An app name required with options: {app: {name: 'APPNAME'}}"
      return callback { message }

    identifier = app.name
    identifier = "#{app.name}_#{app.version}"  if app.version?
    identifier = identifier.replace "\.", ""

    @storage.fetchValue identifier, (preferredUID)=>

      if preferredUID?

        for machine in @machines
          if machine.uid is preferredUID \
            and machine.status.state is Machine.State.Running
              info "Machine returned from previous selection."
              return callback null, machine

        info """There was a preferred machine, but its
                not available now. Asking for another one."""
        @storage.unsetKey identifier

      ComputeController.UI.askMachineForApp app, (err, machine, remember)=>

        if not err and remember
          @storage.setValue identifier, machine.uid

        callback err, machine
