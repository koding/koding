globals              = require 'globals'
Promise              = require 'bluebird'
Encoder              = require 'htmlencode'

kd                   = require 'kd'
KDController         = kd.Controller

nick                 = require 'app/util/nick'
isKoding             = require 'app/util/isKoding'
FSHelper             = require 'app/util/fs/fshelper'
showError            = require 'app/util/showError'
isLoggedIn           = require 'app/util/isLoggedIn'
actions              = require 'app/flux/environment/actions'

remote               = require('../remote')
Machine              = require './machine'
KiteCache            = require '../kite/kitecache'
ComputeStateChecker  = require './computestatechecker'
ComputeEventListener = require './computeeventlistener'
ComputeController_UI = require './computecontroller.ui'
ManagedKiteChecker   = require './managed/managedkitechecker'
envDataProvider      = require 'app/userenvironmentdataprovider'
Tracker              = require 'app/util/tracker'
getGroup             = require 'app/util/getGroup'
createShareModal     = require 'stack-editor/editor/createShareModal'
isGroupDisabled      = require 'app/util/isGroupDisabled'

{ actions : HomeActions } = require 'home/flux'

require './config'

module.exports = class ComputeController extends KDController


  @providers = globals.config.providers
  @Error     = {
    'TimeoutError', 'KiteError', 'NotSupported'
    Pending: '107', NotVerified: '500'
  }

  constructor: ->

    super

    { mainController, groupsController, router } = kd.singletons

    @ui = ComputeController_UI

    do @reset

    remote.once 'ready', =>
      @disabled = getGroup().isDisabled()
      do @reset  if @disabled

    mainController.ready =>

      @bindGroupStatusEvents()

      @on 'MachineBuilt',             => do @reset
      @on 'MachineDestroyed',         => do @reset
      @on 'StackAdminMessageDeleted', @bound 'handleStackAdminMessageDeleted'

      groupsController.on 'StackTemplateChanged', @bound 'checkGroupStacks'
      groupsController.on 'StackAdminMessageCreated', @bound 'handleStackAdminMessageCreated'

      @fetchStacks =>

        @eventListener      = new ComputeEventListener
        @managedKiteChecker = new ManagedKiteChecker
        @stateChecker       = new ComputeStateChecker

        @stateChecker.machines = @machines
        @stateChecker.start()

        @createDefaultStack()

        @storage = kd.singletons.appStorageController.storage 'Compute', '0.0.1'
        @emit 'ready'

        @checkGroupStackRevisions()

        if groupsController.canEditGroup()
          @on 'RenderMachines', @bound 'checkMachinePermissions'
          @checkMachinePermissions()

        @info machine for machine in @machines


  bindGroupStatusEvents: ->

    { groupsController } = kd.singletons

    # /cc @cihangir: not sure if this is the right way to bind the event.
    groupsController.on 'payment_status_changed', ({ oldStatus, newStatus }) =>
      before = @disabled
      @disabled = after = getGroup().isDisabled()

      do @reset  if before isnt after

  # ComputeController internal helpers
  #

  getKloud: ->

    kd.singletons.kontrol.getKite
      name         : 'kloud'
      environment  : globals.config.environment
      version      : globals.config.kites.kloud.version
      username     : globals.config.kites.kontrol.username


  reset: (render = no, callback = -> ) ->

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
          @emit 'RenderMachines', @machines
          @emit 'RenderStacks',   @stacks
          callback null
      , yes

    return this


  _clearTrialCounts: (machine) ->
    @_trials[machine.uid] = {}


  methodNotSupportedBy = (machine, method) ->

    NotSupported = {
      name    : 'NotSupported'
      message : 'Operation is not supported for this VM'
    }

    return NotSupported  unless provider = machine?.provider

    if provider is 'managed'
      return NotSupported

    if method?
      switch method
        when 'reinit'
          return NotSupported  if provider in ['aws', 'vagrant']
        when 'createSnapshot'
          return NotSupported  if provider in ['aws', 'softlayer', 'vagrant']



  errorHandler: (call, task, machine) ->

    { timeout, Error } = ComputeController

    retryIfNeeded = kd.utils.throttle 500, (task, machine) =>

      return  if task in ['info', 'buildStack']

      @_trials[machine.uid]       ?= {}
      @_trials[machine.uid][task] ?= 0

      if @_trials[machine.uid][task]++ <= 3
        kd.info "Trying again to do '#{task}'..."
        @_force = yes
        kd.utils.wait @_trials[machine.uid][task] * 3000, =>
          this[task] machine
        return yes


    (err) =>

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
            safeToSuspend = yes
          else
            kd.warn '[CC] error:', err

        when Error.NotSupported

          kd.info "Cancelling... #{task} ..."
          call.cancel()


      unless safeToSuspend
        @emit 'error', { task, err, machine }
        @emit "error-#{machine._id}", { task, err, machine }

      kd.warn "#{task} failed:", err, this

      @stateChecker.watch machine._id

      return err


  # Fetchers most of these methods has internal
  # caches with in ComputeController

  fetchStacks: do (queue = []) ->

    (callback = kd.noop, force = no) -> kd.singletons.mainController.ready =>

      if @disabled
        callback null, []
        return

      if @stacks.length > 0 and not force
        callback null, @stacks
        return

      return  if (queue.push callback) > 1

      remote.api.JComputeStack.some {}, (err, stacks = []) =>

        if err?
          cb err  for cb in queue
          queue = []
          return

        remote.api.JMachine.some {}, (err, _machines = []) =>

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
            stack.title    = Encoder.htmlDecode stack.title
            stack.machines = stack.machines
              .filter (machineId) => @machinesById[machineId]
              .map    (machineId) => @machinesById[machineId]
            @stacksById[stack._id] = stack

          @stacks   = stacks
          @machines = machines

          @checkStackRevisions()

          @stateChecker?.machines = machines
          @stateChecker?.start()

          globals.userMachines = machines
          @emit 'MachineDataUpdated'

          cb null, stacks  for cb in queue
          queue = []



  fetchMachines: do (queue = []) ->

    (callback = kd.noop) -> kd.singletons.mainController.ready =>

      if @machines.length > 0
        callback null, @machines
        kd.info 'Machines returned from cache.'
        return

      return  if (queue.push callback) > 1

      @fetchStacks (err) =>

        if err?
          cb err  for cb in queue
          queue = []
          return

        cb null, @machines  for cb in queue
        queue = []


  fetchMachine: (idOrUid, callback = kd.noop) ->

    remote.api.JMachine.one idOrUid, (err, machine) ->
      if showError err then callback err
      else if machine? then callback null, new Machine { machine }


  queryMachines: (query = {}, callback = kd.noop) ->

    remote.api.JMachine.some query, (err, machines) ->
      if showError err then callback err
      else callback null, (new Machine { machine } for machine in machines)


  findStackFromRemoteData: (options) ->

    { commitId } = options
    for stack in @stacks when _commitId = stack.config?.remoteDetails?.commitId
      return stack  if ///^#{commitId}///.test _commitId


  findMachineFromRemoteData: (options) ->

    return  unless stack = @findStackFromRemoteData options
    return  stack.machines?.first


  findMachineFromMachineId: (machineId) ->
    return @machinesById[machineId]

  findMachineFromMachineUId: (machineUId) ->
    for machine in @machines when machine.uid is machineUId
      return machine

  findStackFromStackId: (stackId) ->
    return @stacksById[stackId]

  findStackFromMachineId: (machineId) ->
    for stack in @stacks
      for machine in stack.machines
        return stack  if machine._id is machineId

  findStackFromTemplateId: (baseStackId) ->
    return stack  for stack in @stacks when stack.baseStackId is baseStackId

  findMachineFromQueryString: (queryString) ->

    return  unless queryString

    kiteIdOnly = "///////#{queryString.split('/').reverse()[0]}"

    for machine in @machines
      return machine  if machine.queryString in [queryString, kiteIdOnly]


  fetchAvailable: (options, callback) ->
    remote.api.ComputeProvider.fetchAvailable options, callback


  fetchUsage: (options, callback) ->
    remote.api.ComputeProvider.fetchUsage options, callback


  fetchUserPlan: (callback = kd.noop) -> callback 'free'


  fetchRewards: (options, callback) ->

    { unit } = options

    options =
      unit  : 'MB'
      type  : 'disk'

    remote.api.JReward.fetchEarnedAmount options, (err, amount) ->

      if err
        amount = 0
        kd.warn err

      amount = Math.floor amount / 1000  if unit is 'GB'

      callback null, amount


  # create helpers on top of remote.ComputeProvider
  #

  create: (options, callback) ->

    remote.api.ComputeProvider.create options, (err, machine) =>
      return callback err  if err?

      @reset yes, -> callback null, machine


  createDefaultStack: (force, template) ->

    return  unless isLoggedIn()

    { mainController, groupsController } = kd.singletons

    handleStackCreate = (err, newStack) =>
      return kd.warn err  if err
      return kd.warn 'Stack data not found'  unless newStack

      { results : { machines } } = newStack
      [ machine ] = machines

      @reset yes, =>
        @reloadIDE machine.obj.slug
        @checkGroupStacks()

    mainController.ready =>

      if template
        template.generateStack handleStackCreate
      else if force or groupsController.currentGroupHasStack()
        for stack in @stacks
          return  if stack.config?.groupStack
        remote.api.ComputeProvider.createGroupStack handleStackCreate
      else
        @emit 'StacksNotConfigured'


  # remote.ComputeProvider and Kloud kite public methods
  info: (machine) ->

    if @eventListener.followUpcomingEvents machine, yes
      return Promise.resolve()

    @eventListener.triggerState machine,
      status      : machine.status.state
      percentage  : 0

    machineId = machine._id
    currentState = machine.status.state

    call = @getKloud().info { machineId, currentState }

    .then (response) =>

      kd.log 'info response:', response
      @_clearTrialCounts machine
      @eventListener.triggerState machine,
        status      : response.State
        percentage  : 100

      response

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      (@errorHandler call, 'info', machine) err


  destroy: (machine, force) ->

    destroy = (machine) =>

      baseKite = machine.getBaseKite( no )
      if machine?.provider is 'managed' and baseKite.klientDisable?
      then baseKite.klientDisable().finally -> baseKite.disconnect()
      else baseKite.disconnect()

      if machine?.provider is 'managed'

        options     =
          machineId : machine._id
          provider  : machine.provider

        remote.api.ComputeProvider.remove options, (err) =>
          return  if err

          @_clearTrialCounts machine

          # we don't need to wait for deletion of workspace here ~ GG
          remote.api.JWorkspace.deleteByUid machine.uid, (err) ->
            console.warn "couldn't delete workspace:", err  if err

          @reset yes, ->
            ideApp = envDataProvider.getIDEFromUId machine.uid
            ideApp?.quit()

        return

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      call = @getKloud().destroy { machineId: machine._id }

      .then (res) =>

        @_force = no

        kd.log 'destroy res:', res
        @emit 'MachineBeingDestroyed', machine
        @_clearTrialCounts machine
        @eventListener.addListener 'destroy', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        (@errorHandler call, 'destroy', machine) err

    return destroy machine  if force or @_force

    @ui.askFor 'destroy', { machine, force }, (status) ->
      return  unless status.confirmed
      destroy machine


  reinit: (machine, snapshotId) ->

    return  if methodNotSupportedBy machine, 'reinit'

    startReinit = =>

      machine.getBaseKite( no ).disconnect()

      call = @getKloud().reinit { machineId: machine._id, snapshotId }

      .then (res) =>

        @_force = no

        kd.log 'reinit res:', res
        @emit 'MachineBeingDestroyed', machine
        @_clearTrialCounts machine
        @eventListener.addListener 'reinit', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        (@errorHandler call, 'reinit', machine) err

    # A shorthand for ComputeController_UI Askfor
    askFor = (action, callback = kd.noop) =>
      @ui.askFor action, { machine, force: @_force }, (status) ->
        return  unless status.confirmed
        callback status

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


  resize: (machine, resizeTo = 10) ->

    return  if methodNotSupportedBy machine, 'resize'

    @ui.askFor 'resize', {
      machine, force: @_force, resizeTo
    }, (status) =>

      return  unless status.confirmed

      @update machine, { resize: resizeTo }, (err) =>

        if err and err.name isnt 'SameValueForResize'
          return  showError err

        @eventListener.triggerState machine,
          status      : Machine.State.Pending
          percentage  : 0

        machine.getBaseKite( no ).disconnect()

        call = @getKloud().resize { machineId: machine._id }

        .then (res) =>

          @_force = no

          kd.log 'resize res:', res
          @_clearTrialCounts machine
          @eventListener.addListener 'resize', machine._id

        .timeout globals.COMPUTECONTROLLER_TIMEOUT

        .catch (err) =>

          (@errorHandler call, 'resize', machine) err


  build: (machine) ->

    return  if methodNotSupportedBy machine

    @eventListener.triggerState machine,
      status      : Machine.State.Building
      percentage  : 0

    machine.getBaseKite( no ).disconnect()

    call = @getKloud().build { machineId: machine._id }

    .then (res) =>

      kd.log 'build res:', res
      @_clearTrialCounts machine
      @eventListener.addListener 'build', machine._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      (@errorHandler call, 'build', machine) err


  buildStack: (stack, credentials) ->

    verificationNeeded = not credentials
    return  if verificationNeeded and not @verifyStackRequirements stack

    state = stack.status?.state ? 'Unknown'

    unless state is 'NotInitialized'
      if state is 'Building'
        @eventListener.addListener 'apply', stack._id
      else
        kd.warn 'Stack already initialized, skipping.', stack
      return

    stack.machines.forEach (machineId) =>
      return  unless machine = @findMachineFromMachineId machineId

      @eventListener.triggerState machine,
        status      : Machine.State.Building
        percentage  : 0

      machine.getBaseKite( no ).disconnect()

    stackId = stack._id

    HomeActions.markAsDone 'buildStack'
    Tracker.track Tracker.STACKS_START_BUILD, {
      customEvent : { stackId, group : getGroup().slug }
    }

    call = @getKloud().buildStack { stackId, credentials }

    .then (res) =>

      (@findStackFromStackId stackId)?.status.state = 'Building'

      kd.log 'build stack res:', res
      @eventListener.addListener 'apply', stackId

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      (@errorHandler call, 'buildStack', stack) err


  destroyStack: (stack, callback, followEvents = yes) ->

    # TMS-1919: This only takes a stack instance so it's ok
    # for multiple stacks ~ GG

    return  unless stack

    { state } = stack.status

    if state in [ 'Building', 'Destroying' ]
      return callback
        name    : 'InProgress'
        message : "This stack is currently #{state.toLowerCase()}."

    if followEvents then stack.machines.forEach (machineId) =>
      return  unless machine = @findMachineFromMachineId machineId

      @eventListener.triggerState machine,
        status      : Machine.State.Terminating
        percentage  : 0

      machine.getBaseKite( no ).disconnect()

    stackId = stack._id
    call    = @getKloud().buildStack { stackId, destroy: yes }

    .then (res) =>

      actions.reinitStack stack._id
      @eventListener.addListener 'apply', stackId  if followEvents

      Tracker.track Tracker.STACKS_DELETE, {
        customEvent :
          stackId   : stackId
          group     : getGroup().slug
      }

      callback? null

      return res

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) ->
      console.error 'Destroy stack failed:', err
      callback err


  start: (machine) ->

    return  if methodNotSupportedBy machine

    @eventListener.triggerState machine,
      status      : Machine.State.Starting
      percentage  : 0

    machine.getBaseKite( no ).isDisconnected = no

    call = @getKloud().start { machineId: machine._id }

    .then (res) =>

      kd.log 'start res:', res
      @_clearTrialCounts machine
      @eventListener.addListener 'start', machine._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      (@errorHandler call, 'start', machine) err


  stop: (machine) ->

    return  if methodNotSupportedBy machine

    @eventListener.triggerState machine,
      status      : Machine.State.Stopping
      percentage  : 0
      silent      : yes

    machine.getBaseKite( no ).disconnect()

    call = @getKloud().stop { machineId: machine._id }

    .then (res) =>

      kd.log 'stop res:', res
      @_clearTrialCounts machine
      @eventListener.addListener 'stop', machine._id

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      (@errorHandler call, 'stop', machine) err


  setAlwaysOn: (machine, state, callback = kd.noop) ->

    if err = methodNotSupportedBy machine
      return callback err

    Tracker.track Tracker.VM_SET_ALWAYS_ON

    @update machine, { alwaysOn: state }, callback


  update: (machine, options, callback = kd.noop) ->

    updateWith = (options) =>
      remote.api.ComputeProvider.update options, (err) =>
        @triggerReviveFor machine._id  unless err?
        callback err

    { provider }      = machine
    options.machineId = machine._id
    options.provider  = provider

    # For teams context we need to use JMachine.credential field for ongoing
    # operations with ComputeProvider which will need to verify credential
    # on each request. There is one user experience issue with that behaivour
    # which is causing user to reinitialize their stacks if one of the valid
    # credential has been changed. To prevent that we are taking stack template
    # credential if it fits with the current JMachine requirements. So user
    # not requires to re-init their stacks when a credential is changed but not
    # the template itself. ~ GG
    unless isKoding()

      # TMS-1919: This is already written for multiple stacks, just a check
      # might be required ~ GG

      stack = @findStackFromMachineId machine._id
      return updateWith options  unless stack

      @fetchBaseStackTemplate stack, (err, template) ->
        return updateWith options  if err or not template

        credential = template.credentials[provider]?.first ? machine.credential
        options.credential = credential

        updateWith options

    else

      updateWith options

  # Stacks

  # Start helper to start all machines in the given stack
  startStack: (stack) ->

    for machine in stack.machines
      @start machine  if machine.isStopped()


  # Stop helper to stop all machines in the given stack
  stopStack: (stack) ->

    for machine in stack.machines
      @stop machine  if machine.isRunning()


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

    return  if methodNotSupportedBy machine, 'createSnapshot'

    @eventListener.triggerState machine,
      status      : Machine.State.Snapshotting
      percentage  : 0

    # Do we plan to stop machine before snapshot starts? ~ GG
    # machine.getBaseKite( createIfNotExists = no ).disconnect()

    call = @getKloud().createSnapshot { machineId: machine._id, label }

      .then (res) =>

        kd.log 'createSnapshot res:', res
        @eventListener.addListener 'createSnapshot', machine._id

      .timeout globals.COMPUTECONTROLLER_TIMEOUT

      .catch (err) =>

        (@errorHandler call, 'createSnapshot', machine) err


  # Domain management
  #

  fetchDomains: do (queue = []) ->

    (callback = kd.noop) -> kd.singletons.mainController.ready =>

      @domains ?= []

      if @domains.length > 0
        callback null, @domains
        kd.info 'Domains returned from cache.'
        return

      return  if (queue.push callback) > 1

      topDomain = "#{nick()}.#{globals.config.userSitesDomain}"

      remote.api.JDomainAlias.some {}, (err, domains) =>

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

  triggerReviveFor: (machineId, asStack = no) ->

    return  unless machineId

    kd.info "Reviving #{if asStack then 'stack' else 'machine'} #{machineId}..."

    @fetchStacks =>

      if asStack
        if stack = @findStackFromStackId machineId
          @reset yes, =>
            stack.machines.forEach (machine) =>
              @triggerReviveFor machine._id
          return

      remote.api.JMachine.one machineId, (err, machine) =>
        kd.warn "Revive failed for #{machineId}: ", err  if err
        @invalidateCache machineId
        @emit "revive-#{machineId}", machine
        kd.info "Revive triggered for #{machineId}", machine


  invalidateCache: (machineId) ->

    machine = @findMachineFromMachineId machineId

    unless machine?
      return kd.warn \
        "Unable to invalidate cache, machine not found with #{machineId}"

    { kontrol } = kd.singletons

    KiteCache.unset machine.queryString
    delete kontrol.kites?.klient?[machine.uid]


  checkStackRevisions: ->

    return  if isKoding()

    # TMS-1919: This is already written for multiple stacks, code change
    # might be required if existing flow changes ~ GG

    @stacks.forEach (stack) =>

      stack.checkRevision (error, data) =>

        data ?= {}
        { status, machineCount } = data
        stack._revisionStatus = { error, status }

        # console.info "Revision info for stack #{stack.title}", status
        @emit 'StackRevisionChecked', stack

        if stack.machines.length isnt machineCount
          @emit 'StacksInconsistent', stack


  checkGroupStacks: ->

    @checkStackRevisions()

    { groupsController } = kd.singletons
    { slug } = currentGroup = groupsController.getCurrentGroup()

    remote.api.JGroup.one { slug }, (err, _currentGroup) =>
      return kd.warn err  if err
      return kd.warn 'No such Group!'  unless _currentGroup

      currentGroup.stackTemplates = _currentGroup.stackTemplates
      @emit 'GroupStackTemplatesUpdated'

      # TMS-1919: This can stay as is, but this time it will create the first
      # avaiable stacktemplate for who has no stacks yet. ~ GG

      groupStacks = @stacks.filter (stack) -> stack.config?.groupStack

      @createDefaultStack yes  if groupStacks.length is 0

      @checkGroupStackRevisions()


  checkGroupStackRevisions: ->

    return  if isKoding()
    return  if not @stacks?.length

    { groupsController } = kd.singletons
    currentGroup         = groupsController.getCurrentGroup()
    { stackTemplates }   = currentGroup

    return  if not stackTemplates?.length

    existents = 0

    # TMS-1919: This is already written for multiple stacks, just a check
    # might be required ~ GG

    for stackTemplate in stackTemplates
      for stack in @stacks when stack.baseStackId is stackTemplate
        existents++
        break # only count one matched stack ~ GG

    if existents isnt stackTemplates.length
    then @emit 'GroupStacksInconsistent'
    else @emit 'GroupStacksConsistent'


  fixMachinePermissions: (machine, dontAskAgain = no) ->

    { groupsController } = kd.singletons

    # This is for admins only
    return  unless groupsController.canEditGroup()

    @ui.askFor 'permissionFix', { machine, dontAskAgain }, (state) =>

      if state.dontAskAgain is yes

        ignoredMachines = @storage.getValue('ignoredMachines') ? {}
        ignoredMachines[machine.uid] = yes

        @storage.setValue 'ignoredMachines', ignoredMachines

        new kd.NotificationView
          title    : "We won't bother you again for this machine"
          duration : 5000
          content  : 'You can fix permissions anytime you want from
                      settings panel of this machine.'

        return

      return  if not state.confirmed

      notification = new kd.NotificationView
        title    : 'Fixing permissions...'
        duration : 15000

      kloud = @getKloud()
      kloud.addAdmin { machineId: machine._id }
        .finally ->
          notification.destroy()
        .then (shared) ->
          new kd.NotificationView { title: 'Permissions fixed' }
        .catch (err) ->
          showError err, 'Failed to fix permissions'


  checkMachinePermissions: ->

    { groupsController } = kd.singletons

    # This is for admins only
    return  unless groupsController.canEditGroup()

    @machines.forEach (machine) =>

      { oldOwner, permissionUpdated } = machine.jMachine.meta

      return  unless oldOwner
      return  if not machine.isRunning()
      return  if machine.isManaged()

      @storage.fetchValue 'ignoredMachines', (ignoredMachines) =>
        ignoredMachines ?= {}
        return  if ignoredMachines[machine.uid]

        @fixMachinePermissions machine, dontAskAgain = yes


  verifyStackRequirements: (stack) ->

    unless stack
      kd.warn 'Stack not provided:', stack
      return no

    { requiredProviders, requiredData } = stack.config
    provided = stack.credentials
    missings = []

    for provider in requiredProviders when provider isnt 'koding'
      missings.push provider  unless provided[provider]?

    if 'userInput' in missings
      fields = requiredData.userInput
      @ui.requestMissingData {
        requiredFields : fields
        stack
      }, ({ stack, credential }) =>
        @emit 'StackRequirementsProvided', { stack, credential }

      return no

    return yes


  ###*
   * Fetch given stack's stackTemplate which is generated from.
  ###

  fetchBaseStackTemplate: (stack, callback = kd.noop) ->

    return callback null  unless stack?.baseStackId

    { baseStackId } = stack

    @fetchStackTemplate baseStackId, callback


  fetchStackTemplate: (id, callback = kd.noop) ->

    remote.api.JStackTemplate.one { _id: id }, (err, template) ->
      return callback { message: "Stack template doesn't exist." }  if err or not template

      # Follow update events to get change set from remote-extensions
      # This is not required but we will need a huge set of changes
      # to make it happen in a better way, FIXME ~GG
      template.on 'update', kd.noop

      return callback null, template


  showBuildLogs: (machine, tailOffset) ->

    # Not supported for Koding Group
    return  if isKoding()

    # Path of cloud-init-output log
    path = '/var/log/cloud-init-output.log'
    file = FSHelper.createFileInstance { path, machine }

    return  unless ideApp = envDataProvider.getIDEFromUId machine.uid

    ideApp.tailFile {
      file
      description : '
        Your Koding Stack has successfully been initialized. The log here
        describes each executed step of the Stack creation process.
      '
      tailOffset
    }


  ###*
   * Returns the stack which generated from Group's default stack template
  ###
  getGroupStack: ->

    return null  if isKoding() # we may need this for Koding group as well ~ GG
    return null  if not @stacks?.length

    { groupsController } = kd.singletons
    currentGroup         = groupsController.getCurrentGroup()
    { stackTemplates }   = currentGroup

    return null  if not stackTemplates?.length

    for stackTemplate in stackTemplates
      for stack in @stacks when stack.baseStackId is stackTemplate
        return stack

    for stack in @stacks when stack.config?.groupStack
      return stack

    return null


  reloadIDE: (machineSlug) ->

    route   = '/IDE'
    if machineSlug
      route = "/IDE/#{machineSlug}"

    kd.singletons.appManager.quitByName 'IDE', ->
      kd.singletons.router.handleRoute route


  makeTeamDefault: (stackTemplate, revive) ->

    if revive
      stackTemplate = remote.revive stackTemplate
    { credentials, config: { requiredProviders } } = stackTemplate

    { groupsController, reactor } = kd.singletons

    createShareModal (needShare, modal) =>

      groupsController.setDefaultTemplate stackTemplate, (err) =>

        reactor.dispatch 'UPDATE_TEAM_STACK_TEMPLATE_SUCCESS', { stackTemplate }
        reactor.dispatch 'REMOVE_PRIVATE_STACK_TEMPLATE_SUCCESS', { id: stackTemplate._id }

        Tracker.track Tracker.STACKS_MAKE_DEFAULT

        if needShare
        then @shareCredentials credentials, requiredProviders, -> modal.destroy()
        else modal.destroy()


  shareCredentials: (credentials, requiredProviders, callback) ->

    for selectedProvider in requiredProviders
      break  if selectedProvider in ['aws', 'vagrant']

    selectedProvider ?= (Object.keys credentials ? { aws: yes }).first
    selectedProvider ?= 'aws'

    creds = Object.keys credentials
    { groupsController } = kd.singletons

    if creds.length > 0 and credential = credentials["#{selectedProvider}"]?.first
      remote.api.JCredential.one credential, (err, credential) ->
        { slug } = groupsController.getCurrentGroup()
        credential.shareWith { target: slug }, (err) ->
          showError 'Failed to share credential'  if err
          callback()
    else showError 'Failed to share credential'


  ###*
   * Reinit's given stack or groups default stack
   * If stack given, it asks for re-init and first deletes and then calls
   * createDefaultStack again.
   * If not given it tries to find default one and does the same thing, if it
   * can't find the default one, asks to user what to do next.
  ###
  reinitStack: (stack, callback = kd.noop) ->

    stack ?= @getGroupStack()

    if not stack

      if @stacks?.length
        new kd.NotificationView
          title   : "Couldn't find default stack"
          content : 'Please re-init manually'

        return kd.singletons.router.handleRoute '/Home/stacks'

      else
        @createDefaultStack()

      return

    # TMS-1919: This should be re-written from scratch probably,
    # Currently this destroys the existing stack and recreate the default
    # one which is covering the stacktemplate updates and stacktemplate
    # change for the group, but this will be invalid once we have multiple
    # stacks. For this reason, we need to define to flow first for this and
    # change the code based on the flow requirements. ~ GG

    @ui.askFor 'reinitStack', {}, (status) =>

      unless status.confirmed
        callback new Error 'Stack is not reinitialized'
        return

      notification = new kd.NotificationView
        title     : 'Reinitializing stack...'
        duration  : 5000

      @fetchBaseStackTemplate stack, (err, template) =>

        if err or not template
          console.warn 'The base template of the stack has been removed:', stack.baseStackId

        groupStack = stack.config?.groupStack

        @destroyStack stack, (err) =>

          if err
            notification.destroy()
            callback err
            return showError err

          @reset()

            .once 'RenderStacks', (stacks = []) ->
              notification.destroy()
              Tracker.track Tracker.STACKS_REINIT, {
                customEvent :
                  stackId   : stack._id
                  group     : getGroup().slug
              }
              new kd.NotificationView { title : 'Stack reinitialized' }
              callback()

          if template and not groupStack
          then @createDefaultStack no, template
          else @createDefaultStack()

        , followEvents = no

    , ->
      callback new Error 'Stack is not reinitialized'


  handleStackAdminMessageCreated: (data) ->

    { stackIds, message, type } = data.contents
    for stackId in stackIds when stack = @stacksById[stackId]
      stack.config ?= {}
      stack.config.adminMessage = { message, type }

    @emit 'StackAdminMessageReceived'


  handleStackAdminMessageDeleted: (stackId) ->

    stack = @stacksById[stackId]
    return  if not stack or not stack.config

    delete stack.config.adminMessage


  fetchSoloMachines: (callback) ->

    return callback null, @_soloMachines  if @_soloMachines

    remote.api.ComputeProvider.fetchSoloMachines (err, res) =>
      @_soloMachines = res?.machines ? []
      kd.warn err  if err
      callback null, @_soloMachines

