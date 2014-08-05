class ComputeController extends KDController

  @providers = KD.config.providers

  @timeout = 20000

  constructor:->
    super

    { mainController, kontrol } = KD.singletons

    do @reset

    mainController.ready =>

      @kloud         = kontrol.getKite
        name         : "kloud"
        environment  : KD.config.environment

      @eventListener = new ComputeEventListener

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

      KD.remote.api.JStack.some {}, (err, stacks = [])=>

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
    return  unless KD.isLoggedIn()
    KD.remote.api.ComputeProvider.createGroupStack (err, stack)=>
      return  if KD.showError err
      @reset yes


  reset: (render = no)->

    @stacks   = []
    @machines = []

    if render then @fetchStacks =>
      @info machine for machine in @machines
      @emit "renderStacks"


  errorHandler: (call, task, machine)->

    ComputeErrors = {
      "TimeoutError", "KiteError", Pending: "107"
    }

    { timeout }   = ComputeController

    retryIfNeeded = (task, machine)->

      return # FIXME ~ GG

      if task in ['info', 'stop', 'start']
        info "Trying again to do '#{task}' in #{timeout}ms..."
        KD.utils.wait timeout, ->
          KD.singletons.computeController[task] machine

    (err)=>

      @eventListener.revertToPreviousState machine

      switch err.name

        when ComputeErrors.TimeoutError

          retryIfNeeded task, machine
          info "Cancelling... #{task} ..."
          call.cancel()

        when ComputeErrors.KiteError

          if task is 'info'
            if err.code is ComputeErrors.Pending
              retryIfNeeded task, machine
            else
              @eventListener.triggerState machine, status: Machine.State.Unknown

      warn "info err:", err, this


  destroy: (machine)->

    ComputeController.UI.askFor 'destroy', machine, =>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      call = @kloud.destroy { machineId: machine._id }

      .then (res)=>

        log "destroy res:", res
        @eventListener.addListener 'destroy', machine._id

      .timeout ComputeController.timeout

      .catch (err)=>

        (@errorHandler call, 'destroy', machine) err


  build: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Building
      percentage  : 0

    machine.getBaseKite().disconnect()

    call = @kloud.build { machineId: machine._id }

    .then (res)=>

      log "build res:", res
      @eventListener.addListener 'build', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'build', machine) err



  start: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Starting
      percentage  : 0

    call = @kloud.start { machineId: machine._id }

    .then (res)=>

      log "start res:", res
      @eventListener.addListener 'start', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'start', machine) err



  stop: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Stopping
      percentage  : 0

    machine.getBaseKite( createIfExists = no ).disconnect()

    call = @kloud.stop { machineId: machine._id }

    .then (res)=>

      log "stop res:", res
      @eventListener.addListener 'stop', machine._id

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'stop', machine) err



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

    call = @kloud.info { machineId: machine._id }

    .then (response)=>

      log "info response:", response
      @eventListener.triggerState machine,
        status      : response.State
        percentage  : 100

    .timeout ComputeController.timeout

    .catch (err)=>

      (@errorHandler call, 'info', machine) err


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

