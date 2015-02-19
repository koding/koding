htmlencode = require 'htmlencode'
Promise = require 'bluebird'
globals = require 'globals'
remote = require('../remote').getInstance()
showError = require '../util/showError'
isLoggedIn = require '../util/isLoggedIn'
nick = require '../util/nick'
kd = require 'kd'
KDController = kd.Controller
KDNotificationView = kd.NotificationView
ComputeEventListener = require './computeeventlistener'
ComputeStateChecker = require './computestatechecker'
KiteCache = require '../kite/kitecache'
Machine = require './machine'
TerminalModal = require '../terminal/terminalmodal'
ComputeController_UI = require './computecontroller.ui'
require './config'

module.exports = class ComputeController extends KDController

  @providers = globals.config.providers

  @timeout = globals.config.COMPUTECONTROLLER_TIMEOUT

  @Error = {
    'TimeoutError', 'KiteError',
    Pending: '107', NotVerified: '500'
  }

  constructor:->

    super

    { mainController, router } = kd.singletons

    do @reset

    mainController.ready =>

      @on "MachineBuilt",     => do @reset
      @on "MachineDestroyed", => do @reset

      @fetchStacks =>

        @eventListener = new ComputeEventListener
        @stateChecker  = new ComputeStateChecker

        @stateChecker.machines = @machines
        @stateChecker.start()

        kd.singletons
          .paymentController.on 'UserPlanUpdated', =>
            @lastKnownUserPlan = null
            @fetchUserPlan()

        if @stacks.length is 0 then do @createDefaultStack

        @storage = kd.singletons.appStorageController.storage 'Compute', '0.0.1'
        @emit 'ready'

        @info machine for machine in @machines

  getKloud: ->

    kd.singletons.kontrol.getKite
      name         : "kloud"
      environment  : globals.config.environment
      version      : globals.config.kites.kloud.version
      username     : globals.config.kites.kontrol.username


  fetchStacks: do (queue=[])->

    (callback = kd.noop)-> kd.singletons.mainController.ready =>

      if @stacks.length > 0
        callback null, @stacks
        kd.info "Stacks returned from cache."
        return

      return  if (queue.push callback) > 1

      remote.api.JComputeStack.some {}, (err, stacks = [])=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        remote.api.JMachine.some {}, (err, _machines = [])=>

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

          globals.userMachines = machines
          @emit "MachineDataUpdated"

          cb null, stacks  for cb in queue
          queue = []



  fetchMachines: do (queue=[])->

    (callback = kd.noop)-> kd.singletons.mainController.ready =>

      if @machines.length > 0
        callback null, @machines
        kd.info "Machines returned from cache."
        return

      return  if (queue.push callback) > 1

      @fetchStacks (err)=>

        if err?
          cb err  for cb in queue
          queue = []
          return

        cb null, @machines  for cb in queue
        queue = []


  fetchMachine: (idOrUid, callback = kd.noop)->

    remote.api.JMachine.one idOrUid, (err, machine)->
      if showError err then callback err
      else if machine? then callback null, new Machine { machine }


  queryMachines: (query = {}, callback = kd.noop)->

    remote.api.JMachine.some query, (err, machines)=>
      if showError err then callback err
      else callback null, (new Machine { machine } for machine in machines)


  credentialsFor: (provider, callback)->
    remote.api.JCredential.some { provider }, callback

  fetchAvailable: (options, callback)->
    remote.api.ComputeProvider.fetchAvailable options, callback

  fetchUsage: (options, callback)->
    remote.api.ComputeProvider.fetchUsage options, callback

  setAlwaysOn: (machine, state, callback = kd.noop)->

    options =
      machineId : machine._id
      provider  : machine.provider
      alwaysOn  : state

    remote.api.ComputeProvider.update options, (err)=>
      @triggerReviveFor machine._id  unless err?
      callback err


  create: (options, callback)->
    remote.api.ComputeProvider.create options, (err, machine)=>
      @reset yes  unless err?
      callback err, machine

  createDefaultStack: ->
    return  unless isLoggedIn()
    remote.api.ComputeProvider.createGroupStack (err, res)=>
      return  if showError err
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

    retryIfNeeded = kd.utils.throttle 500, (task, machine)=>

      return  if task is 'info'

      @_trials[machine.uid]       ?= {}
      @_trials[machine.uid][task] ?= 0

      if @_trials[machine.uid][task]++ < 2
        kd.info "Trying again to do '#{task}'..."
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
          kd.info "Cancelling... #{task} ..."
          call.cancel()

        when Error.KiteError

          if err.code is Error.Pending
            retried = retryIfNeeded task, machine
            safeToSuspend = yes
          else
            kd.warn "[CC] error:", err

      unless safeToSuspend
        @emit "error", { task, err, machine }
        @emit "error-#{machine._id}", { task, err, machine }

      kd.warn "#{task} failed:", err, this

      @stateChecker.watch machine._id

      return err


  destroy: (machine, force)->

    destroy = (machine)=>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      call = @getKloud().destroy { machineId: machine._id }

      .then (res)=>

        @_force = no

        kd.log "destroy res:", res
        @emit "MachineBeingDestroyed", machine
        @_clearTrialCounts machine
        @eventListener.addListener 'destroy', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err)=>

        (@errorHandler call, 'destroy', machine) err

    return destroy machine  if force or @_force

    ComputeController
      .UI.askFor 'destroy', machine, force, =>
        destroy machine


  reinit: (machine)->

    ComputeController.UI.askFor 'reinit', machine, @_force, =>

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      call = @getKloud().reinit { machineId: machine._id }

      .then (res)=>

        @_force = no

        kd.log "reinit res:", res
        @emit "MachineBeingDestroyed", machine
        @_clearTrialCounts machine
        @eventListener.addListener 'reinit', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err)=>

        (@errorHandler call, 'reinit', machine) err


  resize: (machine, resizeTo = 10)->

    ComputeController.UI.askFor 'resize', machine, @_force, =>

      options =
        machineId : machine._id
        provider  : machine.provider
        resize    : resizeTo

      remote.api.ComputeProvider.update options, (err)=>

        return  if showError err

        @eventListener.triggerState machine,
          status      : Machine.State.Pending
          percentage  : 0

        machine.getBaseKite( createIfNotExists = no ).disconnect()

        call = @getKloud().resize { machineId: machine._id }

        .then (res)=>

          @_force = no

          kd.log "resize res:", res
          @_clearTrialCounts machine
          @eventListener.addListener 'resize', machine._id

        .timeout globals.COMPUTECONTROLLER_TIMEOUT

        .catch (err)=>

          (@errorHandler call, 'resize', machine) err



  build: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Building
      percentage  : 0

    machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @getKloud().build { machineId: machine._id }

    .then (res)=>

      kd.log "build res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'build', machine._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err)=>

      (@errorHandler call, 'build', machine) err



  start: (machine)->

    @eventListener.triggerState machine,
      status      : Machine.State.Starting
      percentage  : 0

    machine.getBaseKite( createIfNotExists = no ).isDisconnected = no

    call = @getKloud().start { machineId: machine._id }

    .then (res)=>

      kd.log "start res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'start', machine._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

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

      kd.log "stop res:", res
      @_clearTrialCounts machine
      @eventListener.addListener 'stop', machine._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

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

      kd.log "info response:", response
      @_clearTrialCounts machine
      @eventListener.triggerState machine,
        status      : response.State
        percentage  : 100

      response

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err)=>

      (@errorHandler call, 'info', machine) err

  # Domain management
  #

  fetchDomains: do (queue=[])->

    (callback = kd.noop)-> kd.singletons.mainController.ready =>

      @domains ?= []

      if @domains.length > 0
        callback null, @domains
        kd.info "Domains returned from cache."
        return

      return  if (queue.push callback) > 1

      topDomain = "#{nick()}.#{globals.config.userSitesDomain}"

      remote.api.JDomainAlias.some {}, (err, domains)=>

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

  fetchPlans: (callback = kd.noop)->

    if @plans
      kd.utils.defer => callback @plans
    else
      remote.api.ComputeProvider.fetchPlans
        provider: "koding"
      , (err, plans)=>
          if err? then kd.warn err
          else @plans = plans
          callback plans

  fetchUserPlan: (callback = kd.noop)->

    if @lastKnownUserPlan?
      return callback @lastKnownUserPlan

    kd.singletons.paymentController.subscriptions (err, subscription)=>

      kd.warn "Failed to fetch subscription:", err  if err?

      if err? or not subscription?
      then callback 'free'
      else callback @lastKnownUserPlan = subscription.planTitle


  triggerReviveFor:(machineId)->

    kd.info "Triggering revive for #{machineId}..."

    remote.api.JMachine.one machineId, (err, machine)=>
      if err? then kd.warn "Revive failed for #{machineId}: ", err
      else
        @emit "revive-#{machineId}", machine
        kd.info "Revive triggered for #{machineId}", machine


  requireMachine: (options = {}, callback = kd.noop)-> @ready =>

    {app} = options
    unless app?.name?
      kd.warn message = "An app name required with options: {app: {name: 'APPNAME'}}"
      return callback { message }

    identifier = app.name
    identifier = "#{app.name}_#{app.version}"  if app.version?
    identifier = identifier.replace "\.", ""

    @storage.fetchValue identifier, (preferredUID)=>

      if preferredUID?

        for machine in @machines
          if machine.uid is preferredUID \
            and machine.status.state is Machine.State.Running
              kd.info "Machine returned from previous selection."
              return callback null, machine

        kd.info """There was a preferred machine, but its
                not available now. Asking for another one."""
        @storage.unsetKey identifier

      ComputeController.UI.askMachineForApp app, (err, machine, remember)=>

        if not err and remember
          @storage.setValue identifier, machine.uid

        callback err, machine


  @reviveProvisioner = (machine, callback)->

    provisioner = machine.provisioners.first

    return callback null  unless provisioner

    {JProvisioner} = remote.api
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
      script = htmlencode.htmlDecode script

      path = provisioner.slug.replace "/", "-"
      path = "/tmp/init-#{path}"
      machine.fs.create { path }, (err, file)=>

        if err or not file
          return new KDNotificationView
            title : "Failed to upload build script."

        script  = "#{envVariables}\n\n#{script}\n"
        script += "\necho $?|kdevent;rm -f #{path};exit"

        file.save script, (err)=>
          return if showError err

          command = "bash #{path};exit"

          if not inTerminal

            new KDNotificationView
              title: "Init script running in background..."

            machine.getBaseKite().exec { command }
              .then (res)->

                new KDNotificationView
                  title: "Init script executed"

                kd.info  "Init script executed : ", res.stdout  if res.stdout
                kd.error "Init script failed   : ", res.stderr  if res.stderr

              .catch (err)->

                new KDNotificationView
                  title: "Init script executed successfully"
                kd.error "Init script failed:", err

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

  setDomain: (machine, newDomain, callback = kd.noop) ->

    @getKloud().setDomain { machineId: machine._id, newDomain }
    .nodeify callback


  fetchPlanCombo: (provider, callback)->

    [callback, provider] = [provider, callback]  unless callback?
    provider ?= "koding"

    @fetchUserPlan (plan)=> @fetchPlans (plans)=>
      @fetchUsage { provider }, (err, usage)=>
        @fetchRewards { unit: 'GB' }, (err, reward)->
          callback err, { plan, plans, usage, reward }

  fetchRewards: (options, callback)->

    {unit} = options

    options =
      unit  : 'MB'
      type  : 'disk'

    remote.api.JReward.fetchEarnedAmount options, (err, amount)->

      if err
        amount = 0
        kd.warn err

      amount = Math.floor amount / 1000  if unit is 'GB'

      callback null, amount


  findMachineFromMachineId: (machineId)->

    for machine in @machines
      return machine  if machine._id is machineId

  findMachineFromQueryString: (queryString)->

    for machine in @machines
      return machine  if machine.queryString is queryString

  invalidateCache: (machineId)->

    machine = @findMachineFromMachineId machineId

    unless machine?
      return kd.warn \
        "Unable to invalidate cache, machine not found with #{machineId}"

    {kontrol} = kd.singletons

    KiteCache.unset machine.queryString
    delete kontrol.kites?.klient?[machine.uid]
