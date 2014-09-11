class ComputeController extends KDController

  @providers = KD.config.providers

  @timeout = 30000

  constructor:->
    super

    { mainController, kontrol } = KD.singletons

    do @reset

    mainController.ready =>

      @kloud         = kontrol.getKite
        name         : "kloud"
        environment  : KD.config.environment

      @eventListener = new ComputeEventListener
      @stateChecker  = new ComputeStateChecker

      @on "MachineBuilt",     => do @reset
      @on "MachineDestroyed", => do @reset

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

      KD.remote.api.JComputeStack.some {}, (err, stacks = [])=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        if stacks.length > 0

          machines = []
          stacks.forEach (stack)->
            stack.machines.forEach (machine, index)->
              machine = new Machine { machine, stack }
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

      if @machines.length > 0
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
        @stateChecker.machines = machines
        @stateChecker.start()

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

  fetchUsage: (options, callback)->
    KD.remote.api.ComputeProvider.fetchUsage options, callback

  create: (options, callback)->
    KD.remote.api.ComputeProvider.create options, callback

  createDefaultStack: ->
    return  unless KD.isLoggedIn()
    KD.remote.api.ComputeProvider.createGroupStack (err, stack)=>
      return  if KD.showError err
      @reset yes


  reset: (render = no)->

    @stacks   = []
    @machines = []
    @plans    = null
    @_trials  = {}

    if render then @fetchStacks =>
      @info machine for machine in @machines
      @emit "MachineDataUpdated"

  _clearTrialCounts: (machine)->
    @_trials[machine.uid] = {}


  errorHandler: (call, task, machine)->

    ComputeErrors = {
      "TimeoutError", "KiteError", Pending: "107"
    }

    { timeout }   = ComputeController

    retryIfNeeded = KD.utils.throttle 500, (task, machine)=>

      return  if task is 'info'

      @_trials[machine.uid]       ?= {}
      @_trials[machine.uid][task] ?= 0

      if @_trials[machine.uid][task]++ < 2
        info "Trying again to do '#{task}'..."
        this[task] machine
        return yes


    (err)=>

      retried = no
      @eventListener.revertToPreviousState machine

      switch err.name

        when ComputeErrors.TimeoutError

          safeToSuspend = yes
          retryIfNeeded task, machine
          info "Cancelling... #{task} ..."
          call.cancel()

        when ComputeErrors.KiteError

          if err.code is ComputeErrors.Pending
            retried = retryIfNeeded task, machine
            safeToSuspend = yes
          else
            @eventListener.triggerState machine, status: Machine.State.Unknown

      unless safeToSuspend
        @emit "error", { task, err, machine }
        @emit "error-#{machine._id}", { task, err, machine }

      warn "#{task} failed:", err, this

      @stateChecker.watch machine._id


  destroy: (machine)->

    ComputeController.UI.askFor 'destroy', machine, =>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      call = @kloud.destroy { machineId: machine._id }

      .then (res)=>

        log "destroy res:", res
        @_clearTrialCounts machine
        @eventListener.addListener 'destroy', machine._id

      .timeout ComputeController.timeout

      .catch (err)=>

        (@errorHandler call, 'destroy', machine) err


  build: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Building
      percentage  : 0

    machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @kloud.build { machineId: machine._id }

    .then (res)=>

      log "build res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'build', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'build', machine) err



  start: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Starting
      percentage  : 0

    machine.getBaseKite( createIfNotExists = no ).isDisconnected = no

    call = @kloud.start { machineId: machine._id }

    .then (res)=>

      log "start res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'start', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'start', machine) err



  stop: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Stopping
      percentage  : 0
      silent      : yes

    machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @kloud.stop { machineId: machine._id }

    .then (res)=>

      log "stop res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'stop', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'stop', machine) err




  followUpcomingEvents: (machine)->

    StateEventMap =

      Stopping    : "stop"
      Building    : "build"
      Starting    : "start"
      Rebooting   : "restart"
      Terminating : "destroy"

    stateEvent = StateEventMap[machine.status.state]

    if stateEvent
      @eventListener.addListener stateEvent, machine._id
      return yes

    return no


  info: (machine)->

    if @followUpcomingEvents machine
      return Promise.resolve()

    @eventListener.triggerState machine,
      status      : machine.status.state
      percentage  : 0

    call = @kloud.info { machineId: machine._id }

    .then (response)=>

      log "info response:", response
      @_clearTrialCounts machine
      @eventListener.triggerState machine,
        status      : response.State
        percentage  : 100

      response

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'info', machine) err


  # Utils beyond this point
  #

  fetchPlans: (callback = noop)->

    if @plans then callback @plans
    else
      KD.remote.api.ComputeProvider.fetchPlans
        provider: "koding"
      , (err, plans)=>
          if err? then warn err
          else @plans = plans
          callback plans

  getUserPlan:->

    knownPlans = ['super', 'professional', 'developer', 'hobbyist']
    flags = KD.whoami().globalFlags or []

    for plan in knownPlans
      return plan  if "plan-#{plan}" in flags

    return 'free'


  handleNewMachineRequest: ->

    plan = @getUserPlan()

    @fetchPlans (plans)=>

      @fetchUsage provider: "koding", (err, usage)->

        return  if KD.showError err

        limits  = plans[plan]
        options = { plan, limits, usage }

        if plan in ['developer', 'professional', 'super']
          new ComputePlansModal.Paid options
        else
          new ComputePlansModal.Free options


  triggerReviveFor:(machineId)->

    info "Triggering revive for #{machineId}..."

    KD.remote.api.JMachine.one machineId, (err, machine)=>
      if err? then warn "Revive failed for #{machineId}: ", err
      else
        @emit "revive-#{machineId}", machine
        info "Revive triggered for #{machineId}", machine


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


  @reviveProvisioner = (machine, callback)->

    provisioner = machine.provisioners.first

    return callback null  unless provisioner

    {JProvisioner} = KD.remote.api
    JProvisioner.one slug: provisioner, callback


  @runInitScript = (machine, inTerminal = yes)->

    { status: { state } } = machine
    unless state is Machine.State.Running
      return new KDNotificationView
        title : "Machine is not running."

    envVariables = ""
    for key, value of machine.stack?.config or {}
      envVariables += """export #{key}="#{value}"\n"""

    @reviveProvisioner machine, (err, provisioner)=>

      if err
        return new KDNotificationView
          title : "Failed to fetch build script."
      else if not provisioner
        return new KDNotificationView
          title : "Provision script is not set."

      {content: {script}} = provisioner
      script = Encoder.htmlDecode script

      path = provisioner.slug.replace "/", "-"
      path = "/tmp/init-#{path}"
      machine.fs.create { path }, (err, file)=>

        if err or not file
          return new KDNotificationView
            title : "Failed to upload build script."

        script  = "#{envVariables}\n\n#{script}\n"
        script += "\necho $?|kdevent;rm -f #{path};exit"

        file.save script, (err)=>
          return if KD.showError err

          command = "bash #{path};exit"

          if not inTerminal

            new KDNotificationView
              title: "Init script running in background..."

            machine.getBaseKite().exec { command }
              .then (res)->

                new KDNotificationView
                  title: "Init script executed"

                info  "Init script executed : ", res.stdout  if res.stdout
                error "Init script failed   : ", res.stderr  if res.stderr

              .catch (err)->

                new KDNotificationView
                  title: "Init script executed successfully"
                error "Init script failed:", err

            return

          modal = new TerminalModal {
            title         : "Running init script for #{machine.getName()}..."
            command       : command
            readOnly      : yes
            destroyOnExit : no
            machine
          }

          modal.once "terminal.event", (data)->

            if data is "0"
              title   = "Installed successfully!"
              content = "You can now safely close this Terminal."
            else
              title   = "An error occured."
              content = """Something went wrong while running build script.
                           Please try again."""

            new KDNotificationView {
              title, content
              type          : "tray"
              duration      : 0
              container     : modal
              closeManually : no
            }

  setDomain: (machine, newDomain, callback = noop) ->

    @kloud.setDomain { machineId: machine._id, newDomain }
    .nodeify callback
