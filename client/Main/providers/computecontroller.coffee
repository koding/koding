class ComputeController extends KDController

  @providers = KD.config.providers

  @timeout = 30000

  @Error = {
    'TimeoutError', 'KiteError',
    Pending: '107', NotVerified: '500'
  }

  constructor:->

    super

    { mainController, router } = KD.singletons

    do @reset

    mainController.ready =>

      @on "MachineBuilt",     => do @reset
      @on "MachineDestroyed", => do @reset

      @fetchStacks =>

        @eventListener = new ComputeEventListener
        @stateChecker  = new ComputeStateChecker

        @stateChecker.machines = @machines
        @stateChecker.start()

        KD.singletons
          .paymentController.on 'UserPlanUpdated', =>
            @lastKnownUserPlan = null
            @fetchUserPlan()

        if @stacks.length is 0 then do @createDefaultStack

        @storage = KD.singletons.appStorageController.storage 'Compute', '0.0.1'
        @emit 'ready'

        @info machine for machine in @machines

  getKloud: ->

    KD.singletons.kontrol.getKite
      name         : "kloud"
      environment  : KD.config.environment
      version      : KD.config.kites.kloud.version
      username     : KD.config.kites.kontrol.username


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

        KD.remote.api.JMachine.some {}, (err, _machines = [])=>

          if err?
            cb err  for cb in queue
            queue = []
            return

          machines = []
          for machine in _machines
            machines.push new Machine { machine }

          @stacks   = stacks
          @machines = machines

          @stateChecker?.machines = machines
          @stateChecker?.start()

          KD.userMachines = machines
          @emit "MachineDataUpdated"

          cb null, stacks  for cb in queue
          queue = []



  fetchMachines: do (queue=[])->

    (callback = noop)-> KD.singletons.mainController.ready =>

      if @machines.length > 0
        callback null, @machines
        info "Machines returned from cache."
        return

      return  if (queue.push callback) > 1

      @fetchStacks (err)=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        cb null, @machines  for cb in queue
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

  setAlwaysOn: (machine, state, callback = noop)->

    options =
      machineId : machine._id
      provider  : machine.provider
      alwaysOn  : state

    KD.remote.api.ComputeProvider.update options, (err)=>
      @triggerReviveFor machine._id  unless err?
      callback err


  create: (options, callback)->
    KD.remote.api.ComputeProvider.create options, (err, machine)=>
      @reset yes  unless err?
      callback err, machine

  createDefaultStack: ->
    return  unless KD.isLoggedIn()
    KD.remote.api.ComputeProvider.createGroupStack (err, res)=>
      return  if KD.showError err
      @reset yes


  reset: (render = no)->

    @stacks   = []
    @machines = []
    @plans    = null
    @_trials  = {}

    if render then @fetchMachines =>
      @info machine for machine in @machines
      @emit "RenderMachines", @machines

  _clearTrialCounts: (machine)->
    @_trials[machine.uid] = {}


  errorHandler: (call, task, machine)->

    { timeout, Error } = ComputeController

    retryIfNeeded = KD.utils.throttle 500, (task, machine)=>

      return  if task is 'info'

      @_trials[machine.uid]       ?= {}
      @_trials[machine.uid][task] ?= 0

      if @_trials[machine.uid][task]++ < 2
        info "Trying again to do '#{task}'..."
        @_force = yes
        this[task] machine
        return yes


    (err)=>

      retried = no
      @_force = no
      @eventListener.revertToPreviousState machine

      switch err.name

        when Error.TimeoutError

          safeToSuspend = task is 'info'
          retryIfNeeded task, machine
          info "Cancelling... #{task} ..."
          call.cancel()

        when Error.KiteError

          if err.code is Error.Pending
            retried = retryIfNeeded task, machine
            safeToSuspend = yes
          else
            warn "[CC] error:", err

      unless safeToSuspend
        @emit "error", { task, err, machine }
        @emit "error-#{machine._id}", { task, err, machine }

      warn "#{task} failed:", err, this

      @stateChecker.watch machine._id

      return err


  destroy: (machine)->

    ComputeController.UI.askFor 'destroy', machine, @_force, =>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      call = @getKloud().destroy { machineId: machine._id }

      .then (res)=>

        @_force = no

        log "destroy res:", res
        @emit "MachineBeingDestroyed", machine
        @_clearTrialCounts machine
        @eventListener.addListener 'destroy', machine._id

      .timeout ComputeController.timeout

      .catch (err)=>

        (@errorHandler call, 'destroy', machine) err


  reinit: (machine)->

    ComputeController.UI.askFor 'reinit', machine, @_force, =>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      call = @getKloud().reinit { machineId: machine._id }

      .then (res)=>

        @_force = no

        log "reinit res:", res
        @emit "MachineBeingDestroyed", machine
        @_clearTrialCounts machine
        @eventListener.addListener 'reinit', machine._id

      .timeout ComputeController.timeout

      .catch (err)=>

        (@errorHandler call, 'reinit', machine) err


  resize: (machine, resizeTo = 10)->

    ComputeController.UI.askFor 'resize', machine, @_force, =>

      options =
        machineId : machine._id
        provider  : machine.provider
        resize    : resizeTo

      KD.remote.api.ComputeProvider.update options, (err)=>

        return  if KD.showError err

        @eventListener.triggerState machine,
          status      : Machine.State.Pending
          percentage  : 0

        machine.getBaseKite( createIfNotExists = no ).disconnect()

        call = @getKloud().resize { machineId: machine._id }

        .then (res)=>

          @_force = no

          log "resize res:", res
          @_clearTrialCounts machine
          @eventListener.addListener 'resize', machine._id

        .timeout ComputeController.timeout

        .catch (err)=>

          (@errorHandler call, 'resize', machine) err



  build: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Building
      percentage  : 0

    machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @getKloud().build { machineId: machine._id }

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

    call = @getKloud().start { machineId: machine._id }

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

    call = @getKloud().stop { machineId: machine._id }

    .then (res)=>

      log "stop res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'stop', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'stop', machine) err




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

      @eventListener.addListener stateEvent, machine._id

      if stateEvent in ["build", "destroy"] and followOthers
        @eventListener.addListener "reinit", machine._id

      return yes

    return no


  info: (machine)->

    if @followUpcomingEvents machine, yes
      return Promise.resolve()

    @eventListener.triggerState machine,
      status      : machine.status.state
      percentage  : 0

    machineId = machine._id
    currentState = machine.status.state

    call = @getKloud().info { machineId, currentState }

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

  # Domain management
  #

  fetchDomains: do (queue=[])->

    (callback = noop)-> KD.singletons.mainController.ready =>

      @domains ?= []

      if @domains.length > 0
        callback null, @domains
        info "Domains returned from cache."
        return

      return  if (queue.push callback) > 1

      topDomain = "#{KD.nick()}.#{KD.config.userSitesDomain}"

      KD.remote.api.JDomainAlias.some {}, (err, domains)=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        # Move topDomain to index 0
        _domains = []
        for jdomain in domains
          if jdomain.domain is topDomain
          then _domains.unshift jdomain
          else _domains.push    jdomain

        @domains = _domains
        cb null, @domains  for cb in queue
        queue = []


  # Utils beyond this point
  #

  fetchPlans: (callback = noop)->

    if @plans
      KD.utils.defer => callback @plans
    else
      KD.remote.api.ComputeProvider.fetchPlans
        provider: "koding"
      , (err, plans)=>
          if err? then warn err
          else @plans = plans
          callback plans

  fetchUserPlan: (callback = noop)->

    if @lastKnownUserPlan?
      return callback @lastKnownUserPlan

    KD.singletons.paymentController.subscriptions (err, subscription)=>

      warn "Failed to fetch subscription:", err  if err?

      if err? or not subscription?
      then callback 'free'
      else callback @lastKnownUserPlan = subscription.planTitle


  handleNewMachineRequest: (callback = noop)->

    return  if @_inprogress
    @_inprogress = yes

    @fetchPlanCombo "koding", (err, info)=>

      if KD.showError err
        return @_inprogress = no

      { plan, plans, usage } = info

      limits  = plans[plan]
      options = { plan, limits, usage }

      if limits.total > 1

        new ComputePlansModal.Paid options
        @_inprogress = no

        callback()
        return

      @fetchMachines (err, machines)=>

        warn err  if err?

        if err? or machines.length > 0
          new ComputePlansModal.Free options
          @_inprogress = no

          callback()

        else if machines.length is 0

          stack   = @stacks.first._id
          storage = plans[plan]?.storage or 3

          @create {
            provider : "koding"
            stack, storage
          }, (err, machine)=>

            @_inprogress = no

            callback()

            unless KD.showError err
              KD.userMachines.push machine


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
              title   = "An error occurred."
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

    @getKloud().setDomain { machineId: machine._id, newDomain }
    .nodeify callback


  fetchPlanCombo:(provider, callback)->

    [callback, provider] = [provider, callback]  unless callback?
    provider ?= "koding"

    @fetchUserPlan (plan)=> @fetchPlans (plans)=>
      @fetchUsage { provider }, (err, usage)->
        callback err, { plan, plans, usage }


  findMachineFromMachineId: (machineId)->

    for machine in @machines
      return machine  if machine._id is machineId

  findMachineFromQueryString: (queryString)->

    for machine in @machines
      return machine  if machine.queryString is queryString

  invalidateCache: (machineId)->

    machine = @findMachineFromMachineId machineId

    unless machine?
      return warn \
        "Unable to invalidate cache, machine not found with #{machineId}"

    {kontrol} = KD.singletons

    KiteCache.unset machine.queryString
    delete kontrol.kites?.klient?[machine.uid]
