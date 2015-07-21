globals              = require 'globals'
Promise              = require 'bluebird'
htmlencode           = require 'htmlencode'

kd                   = require 'kd'
KDController         = kd.Controller
KDNotificationView   = kd.NotificationView

nick                 = require 'app/util/nick'
isKoding             = require 'app/util/isKoding'
showError            = require 'app/util/showError'
isLoggedIn           = require 'app/util/isLoggedIn'

remote               = require('../remote').getInstance()
Machine              = require './machine'
KiteCache            = require '../kite/kitecache'
ComputeStateChecker  = require './computestatechecker'
ComputeEventListener = require './computeeventlistener'
ComputeController_UI = require './computecontroller.ui'
ManagedKiteChecker   = require './managed/managedkitechecker'

require './config'


module.exports = class ComputeController extends KDController

  @providers = globals.config.providers
  @Error     = {
    'TimeoutError', 'KiteError', 'NotSupported'
    Pending: '107', NotVerified: '500'
  }

  constructor: ->

    super

    { mainController, router } = kd.singletons

    do @reset

    mainController.ready =>

      @on "MachineBuilt",     => do @reset
      @on "MachineDestroyed", => do @reset

      @fetchStacks =>

        @eventListener      = new ComputeEventListener
        @managedKiteChecker = new ManagedKiteChecker
        @stateChecker       = new ComputeStateChecker

        @stateChecker.machines = @machines
        @stateChecker.start()

        kd.singletons
          .paymentController.on ['UserPlanUpdated', 'PaypalRequestFinished'], =>
            @lastKnownUserPlan = null
            @fetchUserPlan()

        @createDefaultStack()

        @storage = kd.singletons.appStorageController.storage 'Compute', '0.0.1'
        @emit 'ready'

        @info machine for machine in @machines


  # ComputeController internal helpers
  #

  getKloud: ->

    kd.singletons.kontrol.getKite
      name         : "kloud"
      environment  : globals.config.environment
      version      : globals.config.kites.kloud.version
      username     : globals.config.kites.kontrol.username


  reset: (render = no, callback = ->)->

    @stacks       = []
    @machines     = []
    @machinesById = {}
    @stacksById   = {}
    @plans        = null
    @_trials      = {}

    if render
      environmentDataProvider = require 'app/userenvironmentdataprovider'
      environmentDataProvider.fetch =>
        @fetchStacks =>
          @info machine for machine in @machines
          @emit "RenderMachines", @machines
          @emit "RenderStacks",   @stacks
          callback null
      , yes

    return this


  _clearTrialCounts: (machine)->
    @_trials[machine.uid] = {}


  methodNotSupportedBy = (machine)->
    if machine?.provider is 'managed'
      return {
        name    : 'NotSupported'
        message : 'Operation is not supported for this VM'
      }

  errorHandler: (call, task, machine)->

    { timeout, Error } = ComputeController

    retryIfNeeded = kd.utils.throttle 500, (task, machine)=>

      return  if task in ['info', 'buildStack']

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

        when Error.NotSupported

          kd.info "Cancelling... #{task} ..."
          call.cancel()


      unless safeToSuspend
        @emit "error", { task, err, machine }
        @emit "error-#{machine._id}", { task, err, machine }

      kd.warn "#{task} failed:", err, this

      @stateChecker.watch machine._id

      return err


  # Fetchers most of these methods has internal
  # caches with in ComputeController

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

          @machinesById = {}

          machines = []
          for machine in _machines
            machines.push machine = new Machine { machine }
            @machinesById[machine._id] = machine

          @stacksById = {}
          stacks.forEach (stack) =>
            @stacksById[stack._id] = stack
            stack.machines = stack.machines
              .filter (machineId) => @machinesById[machineId]
              .map    (machineId) => @machinesById[machineId]

          @stacks   = stacks
          @machines = machines

          @checkStackRevisions()

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


  findMachineFromMachineId: (machineId)->
    return @machinesById[machineId]

  findStackFromStackId: (stackId)->
    return @stacksById[stackId]

  findStackFromMachineId: (machineId)->
    for stack in @stacks
      for machine in stack.machines
        return stack  if machine._id is machineId

  findMachineFromQueryString: (queryString)->

    return  unless queryString

    kiteIdOnly = "///////#{queryString.split('/').reverse()[0]}"

    for machine in @machines
      return machine  if machine.queryString in [queryString, kiteIdOnly]


  fetchAvailable: (options, callback)->
    remote.api.ComputeProvider.fetchAvailable options, callback


  fetchUsage: (options, callback)->
    remote.api.ComputeProvider.fetchUsage options, callback


  fetchUserPlan: (callback = kd.noop)->

    if @lastKnownUserPlan?
      return callback @lastKnownUserPlan

    kd.singletons.paymentController.subscriptions (err, subscription)=>

      kd.warn "Failed to fetch subscription:", err  if err?

      if err? or not subscription?
      then callback 'free'
      else callback @lastKnownUserPlan = subscription.planTitle


  fetchPlans: (callback = kd.noop)->

    if @plans
      kd.utils.defer => callback @plans
    else
      remote.api.ComputeProvider.fetchPlans (err, plans)=>
        # If there is an error at least return a simple plan
        # which includes only 'free' plan
        if err? or not plans?
          kd.warn err
          callback { free: total: 1, alwaysOn: 0, storage: 3 }
        else
          @plans = plans
          callback plans


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


  fetchPlanCombo: (provider, callback)->

    [callback, provider] = [provider, callback]  unless callback?
    provider ?= "koding"

    @fetchUserPlan (plan)=> @fetchPlans (plans)=>
      @fetchUsage { provider }, (err, usage)=>
        @fetchRewards { unit: 'GB' }, (err, reward)->
          # If there is an invalid plan set for user
          # or plans failed to fetch, then fallback to 'free' plan
          plan = 'free'  unless plans[plan]?

          callback err, { plan, plans, usage, reward }


  # create helpers on top of remote.ComputeProvider
  #

  create: (options, callback)->
    remote.api.ComputeProvider.create options, (err, machine) =>
      return callback err  if err?
      @reset yes, -> callback null, machine


  createDefaultStack: (force) ->

    return  unless isLoggedIn()

    {mainController, groupsController} = kd.singletons

    create = =>
      remote.api.ComputeProvider.createGroupStack (err, res) =>
        return kd.warn err  if err
        @reset yes

    mainController.ready =>

      if force or groupsController.currentGroupHasStack()
        create()  if @stacks.length is 0
      else
        currentGroup = groupsController.getCurrentGroup()
        currentGroup.fetchMyRoles (err, roles) =>
          return kd.warn err  if err
          @emit 'StacksNotConfigured'  if 'admin' in (roles ? [])


  # remote.ComputeProvider and Kloud kite public methods
  #

  info: (machine)->

    if @eventListener.followUpcomingEvents machine, yes
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


  destroy: (machine, force)->

    destroy = (machine)=>

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      if machine?.provider is 'managed'

        options     =
          machineId : machine._id
          provider  : machine.provider

        remote.api.ComputeProvider.remove options, (err)=>
          return  if err

          @_clearTrialCounts machine

          # we don't need to wait for deletion of workspace here ~ GG
          remote.api.JWorkspace.deleteByUid machine.uid, (err)->
            console.warn "couldn't delete workspace:", err  if err

          @reset yes, ->
            kd.singletons.appManager.tell 'IDE', 'quit'

        return

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

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

    ComputeController_UI.askFor 'destroy', {machine, force}, =>
      destroy machine


  reinit: (machine, snapshotId)->

    return if methodNotSupportedBy machine

    startReinit = =>
      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

      call = @getKloud().reinit { machineId: machine._id, snapshotId }

      .then (res)=>

        @_force = no

        kd.log "reinit res:", res
        @emit "MachineBeingDestroyed", machine
        @_clearTrialCounts machine
        @eventListener.addListener 'reinit', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err)=>

        (@errorHandler call, 'reinit', machine) err

    # A shorthand for ComputeController_UI Askfor
    askFor = (action, callback = kd.noop) =>
      ComputeController_UI.askFor action, {machine, force: @_force},
        callback

    { JSnapshot }     = remote.api
    jMachine          = machine.data
    machineSnapshotId = jMachine?.meta?.snapshotId

    # If a machineSnapshotId exists, we need to validate that the
    # actual *snapshot* belonging to that Id still exists.
    # If the caller supplied a snapshotId, we don't need to bother
    # validating it.
    validateMachineSnapshot = machineSnapshotId and not snapshotId

    # If we don't need to validate the Machine Snapshot,
    # askFor a normal reinit
    unless validateMachineSnapshot
      return askFor 'reinit', startReinit

    # We need to validate that the machineSnapshotId still exists
    JSnapshot.one machineSnapshotId, (err, snapshot) ->
      kd.error err  if err

      # If the snapshot exists in mongo, askFor a normal reinit
      # otherwise, make sure they understand that they are
      # reinitializing to a base image.
      if snapshot
      then askFor 'reinit', startReinit
      else askFor 'reinitNoSnapshot', startReinit


  resize: (machine, resizeTo = 10)->

    return if methodNotSupportedBy machine

    ComputeController_UI.askFor 'resize', {
      machine, force: @_force, resizeTo
    }, =>

      @update machine, resize: resizeTo, (err) =>

        if err and err.name isnt 'SameValueForResize'
          return  showError err

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

    return if methodNotSupportedBy machine

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


  buildStack: (stack) ->

    stack.machines.forEach (machineId) =>
      return  unless machine = @findMachineFromMachineId machineId

      @eventListener.triggerState machine,
        status      : Machine.State.Building
        percentage  : 0

      machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @getKloud().buildStack { stackId: stack._id }

    .then (res) =>

      kd.log "build stack res:", res
      @eventListener.addListener 'apply', stack._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      (@errorHandler call, 'buildStack', stack) err



  start: (machine)->

    return if methodNotSupportedBy machine

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

    return if methodNotSupportedBy machine

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


  setAlwaysOn: (machine, state, callback = kd.noop)->

    if err = methodNotSupportedBy machine
      return callback err

    @update machine, alwaysOn: state, callback


  update: (machine, options, callback = kd.noop)->

    options.machineId = machine._id
    options.provider  = machine.provider

    remote.api.ComputeProvider.update options, (err)=>
      @triggerReviveFor machine._id  unless err?
      callback err

  # Snapshots
  #

  ###*
   * Create a snapshot for the given machine. For progress updates,
   * subscribe to computeController's `"createSnapshot-#{machine._id}"`
   * event.
   *
   * @param {Machine} machine - The Machine to create a snapshot from
   * @param {String} label - The label (name) of the snapshot
   * @return {Promise}
   * @emits ComputeController~createSnapshot-machineId
  ###
  createSnapshot: (machine, label) ->

    return if methodNotSupportedBy machine

    @eventListener.triggerState machine,
      status      : Machine.State.Snapshotting
      percentage  : 0

    # Do we plan to stop machine before snapshot starts? ~ GG
    # machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @getKloud().createSnapshot { machineId: machine._id, label }

      .then (res) =>

        kd.log "createSnapshot res:", res
        @eventListener.addListener 'createSnapshot', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        (@errorHandler call, 'createSnapshot', machine) err


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


  setDomain: (machine, newDomain, callback = kd.noop) ->

    @getKloud().setDomain { machineId: machine._id, newDomain }
    .nodeify callback


  # Utils beyond this point
  #

  triggerReviveFor:(machineId)->

    kd.info "Triggering revive for #{machineId}..."

    remote.api.JMachine.one machineId, (err, machine)=>
      if err? then kd.warn "Revive failed for #{machineId}: ", err
      else
        @emit "revive-#{machineId}", machine
        kd.info "Revive triggered for #{machineId}", machine


  invalidateCache: (machineId)->

    machine = @findMachineFromMachineId machineId

    unless machine?
      return kd.warn \
        "Unable to invalidate cache, machine not found with #{machineId}"

    {kontrol} = kd.singletons

    KiteCache.unset machine.queryString
    delete kontrol.kites?.klient?[machine.uid]


  checkStackRevisions: ->

    return  if isKoding()

    @stacks.forEach (stack) =>

      stack.checkRevision (error, data) =>

        { status, machineCount } = data
        stack._revisionStatus = { error, status }

        console.info "Revision info for stack #{stack.title}", status
        @emit 'StackRevisionChecked', stack

        if stack.machines.length isnt machineCount
          @emit 'StacksInconsistent', stack