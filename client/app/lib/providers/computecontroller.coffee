debug                = (require 'debug') 'cc'
globals              = require 'globals'
Promise              = require 'bluebird'
Encoder              = require 'htmlencode'

kd                   = require 'kd'
KDController         = kd.Controller

nick                 = require 'app/util/nick'
FSHelper             = require 'app/util/fs/fshelper'
showError            = require 'app/util/showError'
showNotification     = require 'app/util/showNotification'
isLoggedIn           = require 'app/util/isLoggedIn'
isGroupDisabled      = require 'app/util/isGroupDisabled'
canCreateStacks      = require 'app/util/canCreateStacks'
actions              = require 'app/flux/environment/actions'

remote               = require '../remote'
KiteCache            = require '../kite/kitecache'
ComputeStateChecker  = require './computestatechecker'
ComputeEventListener = require './computeeventlistener'
ComputeController_UI = require './computecontroller.ui'
ManagedKiteChecker   = require './managed/managedkitechecker'
Tracker              = require 'app/util/tracker'
getGroup             = require 'app/util/getGroup'
createShareModal     = require 'stack-editor/editor/createShareModal'
ContentModal         = require 'app/components/contentModal'
runMiddlewares       = require 'app/util/runMiddlewares'
SidebarFlux          = require 'app/flux/sidebar'
whoami               = require 'app/util/whoami'
ComputeStorage       = require './computestorage'
IDERoutes            = require 'ide/routes'

TestMachineMiddleware = require './middlewares/testmachine'


{ actions : HomeActions } = require 'home/flux'
require './config'


module.exports = class ComputeController extends KDController


  PROVIDERS  = globals.config.providers._getSupportedProviders()
  @Error     = {
    'TimeoutError', 'KiteError', 'NotSupported'
    Pending: '107', NotVerified: '500'
  }

  @getMiddlewares = ->
    return [
      TestMachineMiddleware.ComputeController
    ]

  constructor: ->

    super

    { mainController, groupsController, router } = kd.singletons

    @ui = ComputeController_UI
    @storage = new ComputeStorage

    @_trials = {}

    mainController.ready =>
      { appStorageController, notificationController } = kd.singletons

      @bindPaymentEvents()

      @on 'StackAdminMessageDeleted', @bound 'handleStackAdminMessageDeleted'

      groupsController.on 'StackTemplateChanged', (event) => @checkGroupStacks event?.contents
      groupsController.on 'StackAdminMessageCreated', @bound 'handleStackAdminMessageCreated'
      groupsController.on 'SharedStackTemplateAccessLevel', @bound 'sharedStackTemplateAccessLevel'

      @eventListener      = new ComputeEventListener
      @managedKiteChecker = new ManagedKiteChecker
      @stateChecker       = new ComputeStateChecker { @storage }
      @stateChecker.start()

      @createDefaultStack()

      @appStorage = appStorageController.storage 'Compute', '0.0.1'

      debug 'now ready'
      @emit 'ready'

      @checkGroupStackRevisions()
      @checkGroupStacks()
      @checkMachines()

      if groupsController.canEditGroup()

        notificationController.on 'DisabledUserStackAdded', (data) =>
          debug 'disabled user stack added', data
          @checkMachinePermissions()

        @checkMachinePermissions()


  # ComputeController internal helpers
  #

  getKloud: ->

    kd.singletons.kontrol.getKite
      name         : 'kloud'
      environment  : globals.config.environment
      version      : globals.config.kites.kloud.version
      username     : globals.config.kites.kontrol.username


  checkMachines: ->
    for machine in (@storage.machines.get()) when machine.isBuilt()
      @info machine


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


  fetchMachine: (query = {}, callback = kd.noop) ->

    remote.api.JMachine.one query, (err, machine) ->
      if showError err then callback err
      else if machine? then callback null, machine


  queryMachines: (query = {}, callback = kd.noop) ->

    remote.api.JMachine.some query, (err, machines) ->
      if showError err then callback err
      else callback null, machines


  findStackFromRemoteData: (options) ->

    { commitId } = options
    _stacks = @storage.stacks.get()
    for stack in _stacks when _commitId = stack.config?.remoteDetails?.commitId
      return stack  if ///^#{commitId}///.test _commitId


  findMachineFromRemoteData: (options) ->

    return  unless stack = @findStackFromRemoteData options
    return  stack.machines?.first


  findMachineFromMachineId: (machineId) ->
    return @storage.machines.get '_id', machineId

  findMachineFromMachineUId: (machineUId) ->
    return @storage.machines.get 'uid', machineUId

  findStackFromStackId: (stackId) ->
    return @storage.stacks.get '_id', stackId

  findStackFromMachineId: (machineId) ->
    for stack in @storage.stacks.get()
      for machine in stack.machines
        return stack  if machine._id is machineId

  findStackFromTemplateId: (baseStackId) ->
    return @storage.stacks.get 'baseStackId', baseStackId

  findMachineFromQueryString: (queryString) ->

    return  unless queryString

    kiteIdOnly = "///////#{queryString.split('/').reverse()[0]}"

    for machine in @storage.machines.get()
      return machine  if machine.queryString in [queryString, kiteIdOnly]


  fetchAvailable: (options, callback) ->
    remote.api.ComputeProvider.fetchAvailable options, callback


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

    kallback = (err, machine) =>
      return callback err  if err?
      @storage.machines.push machine
      callback null, machine

    runMiddlewares this, 'create', options, (err, newOptions) ->
      if newOptions.shouldStop
        return kallback err, newOptions.machine

      remote.api.ComputeProvider.create newOptions, kallback


  createDefaultStack: (options = {}, callback = kd.noop) ->

    debug 'createDefaultStack called', options

    return  unless isLoggedIn()

    { force = no, template } = options
    { mainController, groupsController } = kd.singletons

    handleStackCreate = (err, newStack) =>

      debug 'createDefaultStack got the new stack:', { err, newStack }

      return kd.warn err  if err
      return callback err  if err
      return kd.warn 'Stack data not found'  unless newStack

      { results : { machines } } = newStack

      kd.utils.defer =>
        @reloadIDE machines[0].obj
        showNotification
          content  : 'A new stack generated and ready to build!'
          type     : 'success'
          duration : 3000
        callback null, newStack

      @checkGroupStacks newStack.stack.getId()


    mainController.ready =>

      if template
        debug 'createDefaultStack creating from template', template
        template.generateStack {}, handleStackCreate
      else if force or groupHasStacks = groupsController.currentGroupHasStack()
        if groupHasStacks and not @storage.stacks.get 'config.groupStack', true
          debug 'createDefaultStack creating default group stack'
          remote.api.ComputeProvider.createGroupStack handleStackCreate
        else
          debug 'createDefaultStack this is an unknown case for me', groupHasStacks, force,
      else
        debug 'createDefaultStack there is no stack configured yet'
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

    stack = @findStackFromMachineId machine._id

    destroy = (machine) =>

      baseKite = machine.getBaseKite no

      if machine.isManaged()

        baseKite.klientDisable?()
          .catch (err) ->
            console.warn 'klient.disabled failed:', err
          .finally ->
            baseKite.disconnect()

        options     =
          machineId : machine._id
          provider  : machine.provider

        remote.api.ComputeProvider.remove options, (err) =>
          return  if err

          @_clearTrialCounts machine

          @storage.machines.pop machine
          stack.machines = stack.machines.filter (m) -> m._id isnt machine._id
          @storage.stacks.push stack

          { appManager } = kd.singletons
          ideApp = appManager.getInstance 'IDE', 'mountedMachineUId', machine.uid
          ideApp?.quit reload = no

        return

      else
        baseKite.disconnect()

      @eventListener.triggerState machine,
        status      : remote.api.JMachine.State.Terminating
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


  build: (machine) ->

    return  if methodNotSupportedBy machine

    @eventListener.triggerState machine,
      status      : remote.api.JMachine.State.Building
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

    stack.machines.forEach (machine) =>
      @eventListener.triggerState machine,
        status      : remote.api.JMachine.State.Building
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

    stack = @storage.stacks.get '_id', stack._id

    { state } = stack.status

    if state in [ 'Building', 'Destroying' ]
      return callback
        name    : 'InProgress'
        message : "This stack is currently #{state.toLowerCase()}."

    stack.machines.forEach (machine) =>

      @storage.machines.pop machine
      @eventListener.triggerState machine,
        status      : remote.api.JMachine.State.Terminating
        percentage  : 0

      machine.getBaseKite( no ).disconnect()

    stackId = stack._id
    call    = @getKloud().buildStack { stackId, destroy: yes }

    .then (res) =>

      @storage.stacks.pop stackId
      actions.checkTeamStack stack._id

      @eventListener.addListener 'apply', stackId  if followEvents

      Tracker.track Tracker.STACKS_DELETE, {
        customEvent :
          stackId   : stackId
          group     : getGroup().slug
      }

      callback? null

      return res

    .timeout globals.COMPUTECONTROLLER_TIMEOUT

    .catch (err) =>

      stack.machines.forEach (machine) =>
        @storage.machines.push machine

      console.error 'Destroy stack failed:', err
      callback err


  start: (machine) ->

    return  if methodNotSupportedBy machine

    @eventListener.triggerState machine,
      status      : remote.api.JMachine.State.Starting
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
      status      : remote.api.JMachine.State.Stopping
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

    # TMS-1919: This is already written for multiple stacks, just a check
    # might be required ~ GG

    stack = @findStackFromMachineId machine._id
    return updateWith options  unless stack

    @fetchBaseStackTemplate stack, (err, template) ->
      return updateWith options  if err or not template

      credential = template.credentials[provider]?.first ? machine.credential
      options.credential = credential

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


  # Utils beyond this point
  #

  triggerReviveFor: (instanceId, asStack = no) ->

    return  unless instanceId

    kd.info "Reviving #{if asStack then 'stack' else 'machine'} #{instanceId}..."

    if asStack

      this.storage.stacks.fetch '_id', instanceId, reset = yes
        .then (stack) =>
          stack.machines.forEach (machine) =>
            @invalidateCache machine.getId()
            @emit "revive-#{machine.getId()}", machine
          return stack
        .catch (err) ->
          kd.warn "Revive failed for #{instanceId}: ", err

    else

      this.storage.machines.fetch '_id', instanceId, reset = yes
        .then (machine) =>
          @invalidateCache instanceId
          @emit "revive-#{instanceId}", machine
          return machine
        .catch (err) ->
          kd.warn "Revive failed for #{instanceId}: ", err


  invalidateCache: (machineId) ->

    machine = @findMachineFromMachineId machineId

    unless machine?
      return kd.warn \
        "Unable to invalidate cache, machine not found with #{machineId}"

    { kontrol } = kd.singletons

    KiteCache.unset machine.queryString
    delete kontrol.kites?.klient?[machine.uid]


  checkStackRevisions: (stackTemplateId, createIfNotFound = yes) ->

    debug 'checkStackRevisions', stackTemplateId
    found = no

    # fetch all the stacks in cache
    (@storage.stacks.get()).forEach (stack) =>

      debug 'checkStackRevisions checking:', stack

      # if a specific stackTemplateId provided then skip all others
      # otherwise check all of them one by one
      if stackTemplateId and stack.baseStackId isnt stackTemplateId
        return

      found = yes

      # get current revision status for comparison
      { _revisionStatus } = stack

      debug 'checkStackRevisions currentRevision:', _revisionStatus

      # check revision from JComputeStack.checkRevision
      stack.checkRevision (error, data) =>

        debug 'checkStackRevisions checkRevision result', error, data

        data ?= {}
        { status, machineCount } = data
        stack._revisionStatus = { error, status }

        debug "revision info for stack #{stack.title}", status
        if not _revisionStatus or _revisionStatus.status isnt status
          debug 'checkStackRevisions stack changed!', stack
          @storage.stacks.push stack
          @emit 'StackRevisionChecked', stack

    if stackTemplateId and not found and createIfNotFound
      @createDefaultStack()


  setStackTemplateAccessLevel: (template, type) ->
    template.setAccess type


  sharedStackTemplateAccessLevel: (params) ->

    { reactor } = kd.singletons
    { contents: { id: _id, change: { $set: { accessLevel } } } } = params

    @fetchStackTemplate _id, (err, stackTemplate) =>

      return kd.NotificationView { title: 'Error occurred' }  if err

      reactor.dispatch 'REMOVE_STACK_TEMPLATE_SUCCESS', { id: _id }

      stackTemplate.setAt 'accessLevel', accessLevel

      debug 'stack template access level is set', accessLevel

      if accessLevel is 'group'
        new kd.NotificationView { title : 'Stack Template is Shared With Team' }
        @checkRevisionFromOriginalStackTemplate stackTemplate
      else
        @removeRevisionFromUnSharedStackTemplate _id, stackTemplate
        @storage.templates.pop stackTemplate  unless stackTemplate.isMine()
        new kd.NotificationView { title : 'Stack Template is Unshared With Team' }


  removeRevisionFromUnSharedStackTemplate: (id, stackTemplate) ->

    { reactor } = kd.singletons

    debug 'remove revision', { id, accessLevel: stackTemplate.accessLevel }

    if stackTemplate
      reactor.dispatch 'UPDATE_PRIVATE_STACK_TEMPLATE_SUCCESS', { stackTemplate }
      SidebarFlux.actions.makeVisible 'draft', id

    stacks = (@storage.stacks.get()).filter (stack) ->
      stack.config?.clonedFrom is id

    stacks.forEach (stack) =>
      config = stack.config ?= {}
      config.needUpdate = no
      @updateStackConfig stack, config


  checkRevisionFromOriginalStackTemplate: (stackTemplate) ->

    { reactor } = kd.singletons

    debug 'check revision', { accessLevel: stackTemplate.accessLevel }

    reactor.dispatch 'UPDATE_TEAM_STACK_TEMPLATE_SUCCESS', { stackTemplate }
    if whoami()._id is stackTemplate.originId
      SidebarFlux.actions.makeVisible 'draft', stackTemplate._id

    stacks = (@storage.stacks.get()).filter (stack) ->
      stack.config?.clonedFrom is stackTemplate._id

    return  unless stacks.length
    stacks.forEach (stack) =>
      @fetchBaseStackTemplate stack, (err, template) =>
        unless err
          if stackTemplate.config.clonedSum isnt template.template.sum
            config = stack.config ?= {}
            config.needUpdate = yes
            @updateStackConfig stack, config


  updateStackConfig: (stack, config) ->
    { reactor } = kd.singletons
    stack.modify { config }, (err) ->
      stack.config = config
      reactor.dispatch 'STACK_UPDATED', stack


  checkGroupStacks: (changedStackTemplateId) ->

    @checkStackRevisions changedStackTemplateId

    # check if there is a stackTemplate assigned to this team
    { stackTemplates } = kd.singletons.groupsController.getCurrentGroup()
    return  unless stackTemplates?.length

    # if so, this time check for existing stacks marked as groupStack
    groupStacks = @storage.stacks.query 'config.groupStack', yes
    if groupStacks.length is 0
      # if not found try to create the default stack
      @createDefaultStack { force: yes }

    @checkGroupStackRevisions()


  checkGroupStackRevisions: ->

    debug 'checkGroupStackRevisions', @storage.stacks.get()

    return  if not (@storage.stacks.get()).length

    { groupsController } = kd.singletons
    currentGroup         = groupsController.getCurrentGroup()
    { stackTemplates }   = currentGroup

    debug 'checkGroupStackRevisions on group:', stackTemplates

    return  if not stackTemplates?.length

    existents = 0
    for stackTemplateId in stackTemplates
      existentStacks = @storage.stacks.query 'baseStackId', stackTemplateId
      existentStacks = existentStacks.filter (stack) -> not stack.getOldOwner()
      existents += existentStacks.length

    debug 'checkGroupStackRevisions existents', existents, stackTemplates.length

    if existents isnt stackTemplates.length
    then @emit 'GroupStacksInconsistent'
    else @emit 'GroupStacksConsistent'


  ignoreMachine: (machine) ->

    ignoredMachines = @appStorage.getValue('ignoredMachines') ? {}
    ignoredMachines[machine.uid] = yes

    @appStorage.setValue 'ignoredMachines', ignoredMachines


  fixMachinePermissions: (machine, dontAskAgain = no) ->

    { groupsController } = kd.singletons

    # This is for admins only
    return  unless groupsController.canEditGroup()

    @ui.askFor 'permissionFix', { machine, dontAskAgain }, (state) =>

      if state.dontAskAgain is yes

        @ignoreMachine machine

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
        .then (shared) =>
          debug 'fixed permissions', shared
          @ignoreMachine machine
          new kd.NotificationView { title: 'Permissions fixed' }
        .catch (err) ->
          showError err


  checkMachinePermissions: ->

    { groupsController } = kd.singletons

    # This is for admins only
    return  unless groupsController.canEditGroup()

    (@storage.machines.get()).forEach (machine) =>

      { oldOwner, permissionUpdated } = machine.meta

      return  unless oldOwner
      return  if not machine.isRunning()
      return  if machine.isManaged()

      @appStorage.fetchValue 'ignoredMachines', (ignoredMachines) =>
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

    for provider in requiredProviders
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

    @storage.templates.fetch(id).nodeify callback


  fetchStackTemplates: (callback) ->

    if (templates = @storage.templates.get()).length
      return callback null, templates

    query   = { group: getGroup().slug }
    options = { limit: 60 }

    remote.api.JStackTemplate.some query, options, (err, templates) =>
      return callback err  if err

      for template in templates
        @storage.templates.push template

      callback null, templates


  showBuildLogs: (machine, tailOffset) ->

    showLogs = -> kd.utils.wait 1000, ->

      # Path of cloud-init-output log
      path = '/var/log/cloud-init-output.log'
      file = FSHelper.createFileInstance { path, machine }

      { appManager } = kd.singletons
      ideApp = appManager.getInstance 'IDE', 'mountedMachineUId', machine.uid
      return  unless ideApp

      ideApp.tailFile {
        file
        description : '
          Your Koding Stack has successfully been initialized. The log here
          describes each executed step of the Stack creation process.
        '
        tailOffset
      }

    if not Cookies.get 'use-ose'
      { router } = kd.singletons
      router.once 'RouteInfoHandled', showLogs
      router.handleRoute "/IDE/#{machine.getAt 'slug'}"
    else
      do showLogs


  ###*
   * Returns the stack which generated from Group's default stack template
  ###
  getGroupStack: ->

    return null  if not (@storage.stacks.get()).length

    { groupsController } = kd.singletons
    currentGroup         = groupsController.getCurrentGroup()
    { stackTemplates }   = currentGroup

    return null  if not stackTemplates?.length

    for stackTemplate in stackTemplates
      stack = @storage.stacks.get 'baseStackId', stackTemplate
      break  if stack

    stack ?= @storage.stacks.get 'config.groupStack', yes

    return stack


  reloadIDE: (machine) ->

    route = '/IDE'
    { appManager, router } = kd.singletons

    if machine

      route = "/IDE/#{machine.slug}"
      ideApp = appManager.getInstance 'IDE', 'mountedMachineUId', machine.uid
      ideApp?.quit()

      if router.currentPath is route
        return IDERoutes.loadIDE { machine, username: nick() }

    router.handleRoute route


  makeTeamDefault: (options, callback = kd.noop) ->

    { template, force = no } = options
    { reactor } = kd.singletons

    @ui.createShareModal ({ modal, shareStack, shareCredential }) ->

      unless shareStack
        return callback { message: 'User cancelled' }

      remote.api.ComputeProvider.setGroupStack {
        templateId: template._id
        shareCredential
      }, (err) ->

        callback err

        return  if showError err

        reactor.dispatch 'UPDATE_TEAM_STACK_TEMPLATE_SUCCESS', { stackTemplate: template }
        reactor.dispatch 'REMOVE_PRIVATE_STACK_TEMPLATE_SUCCESS', { id: template._id }

        Tracker.track Tracker.STACKS_MAKE_DEFAULT

        modal?.destroy()

    , force


  removeClonedFromAttr: (stackTemplate, callback = kd.noop) ->

    @ui.askFor 'dontWarnMe', {}, (status) =>

      return callback yes  unless status.confirmed

      { reactor } = kd.singletons

      stack = @findStackFromTemplateId stackTemplate._id
      { config } = stack

      delete config.clonedFrom
      delete config.needUpdate

      stack.modify { config }, (err) ->
        reactor.dispatch 'STACK_UPDATED', stack

      { config } = stackTemplate

      delete config.clonedFrom
      delete config.needUpdate

      stackTemplate.update { config }, (err) ->
        reactor.dispatch 'UPDATE_STACK_TEMPLATE_SUCCESS', { stackTemplate }
        callback no


  ###*
   * Reinit's given stack or groups default stack
   * If stack given, it asks for re-init and first deletes and then calls
   * createDefaultStack again.
   * If not given it tries to find default one and does the same thing, if it
   * can't find the default one, asks to user what to do next.
  ###
  reinitStack: (stack, callback = kd.noop) ->

    stackProvided = stack?
    stack ?= @getGroupStack()

    debug 'reinitStack called', stack, @getGroupStack()

    if not stack

      if not (@storage.stacks.get()).length
        new kd.NotificationView
          title   : "Couldn't find default stack"
          content : 'Please re-init manually'

        return kd.singletons.router.handleRoute '/Home/stacks'

      else
        @createDefaultStack {}, callback

      return

    # TMS-1919: This should be re-written from scratch probably,
    # Currently this destroys the existing stack and recreate the default
    # one which is covering the stacktemplate updates and stacktemplate
    # change for the group, but this will be invalid once we have multiple
    # stacks. For this reason, we need to define to flow first for this and
    # change the code based on the flow requirements. ~ GG

    @ui.askFor 'reinitStack', {}, (status) =>

      debug 'reinitStack question answered', status

      return  if status.cancelled

      unless status.confirmed
        callback new Error 'Stack is not reinitialized'
        return

      currentGroup = kd.singletons.groupsController.getCurrentGroup()

      notification = new kd.NotificationView
        title     : 'Reinitializing stack...'
        duration  : 5000

      debug 'reinitStack fetching base stackTemplate'

      @fetchBaseStackTemplate stack, (err, template) =>

        debug 'reinitStack base stackTemplate', err, template

        if err or not template
          console.warn 'The base template of the stack has been removed:', stack.baseStackId

        debug 'reinitStack going to destroy old stack', stack

        @destroyStack stack, (err) =>

          debug 'reinitStack destroy old stack result', err

          if err
            notification.destroy()
            callback err
            return showError err

          notification.destroy()
          Tracker.track Tracker.STACKS_REINIT, {
            customEvent :
              stackId   : stack._id
              group     : getGroup().slug
          }
          new kd.NotificationView { title : 'Stack reinitialized' }

          if template and stackProvided and template._id not in (currentGroup.stackTemplates ? [])
            debug 'reinitStack will generate new stack', { template }
            @createDefaultStack { force: no, template }, callback
          else
            debug 'reinitStack will generate group default stack'
            @createDefaultStack {}, callback

        , followEvents = no

    , ->
      callback new Error 'Stack is not reinitialized'


  handleStackAdminMessageCreated: (data) ->

    { stackIds, message, type } = data.contents
    for stackId in stackIds when stack = @findStackFromStackId stackId
      stack.config ?= {}
      stack.config.adminMessage = { message, type }

    @emit 'StackAdminMessageReceived'


  handleStackAdminMessageDeleted: (stackId) ->

    stack = @findStackFromStackId stackId
    return  if not stack or not stack.config

    delete stack.config.adminMessage


  deleteStackTemplate: (template) ->

    { groupsController, computeController, router, reactor }  = kd.singletons
    currentGroup  = groupsController.getCurrentGroup()

    if template._id in (currentGroup.stackTemplates ? [])
      return showError 'This template currently in use by the Team.'

    if computeController.findStackFromTemplateId template._id
      return showError 'You currently have a stack generated from this template.'

    title       = 'Are you sure?'
    description = '<h2>Do you want to delete this stack template?</h2>'
    callback    = ({ status, modal }) ->
      return  unless status

      actions.removeStackTemplate template
        .then ->
          router.handleRoute '/IDE'
          modal.destroy()
        .catch (err) ->
          new kd.NotificationView { title: 'Something went wrong!' }
          modal.destroy()


    template.hasStacks (err, result) ->
      return showError err  if err

      if result
        description = '''<p>
          There is a stack generated from this template by another team member.
          Deleting it can break their stack.</p>
          <p>Do you still want to delete this stack template?</p>
        '''

      modal = new ContentModal
        width : 400
        overlay : yes
        cssClass : 'delete-stack-template content-modal'
        title   : title
        content : description
        buttons :
          cancel      :
            title     : 'Cancel'
            cssClass  : 'solid medium'
            callback  : ->
              modal.destroy()
              callback { status : no }
          ok          :
            title     : 'Yes'
            cssClass  : 'solid medium'
            callback  : -> callback { status : yes, modal }

      modal.setAttribute 'testpath', 'RemoveStackModal'


  infoTest: (machine) ->
    ComputeHelpers = require './computehelpers'
    ComputeHelpers.infoTest machine


  # FIXMERESET ~ GG
  handleChangesOverAPI: (change) ->

    # TODO implement better next to flows here ~ GG

    if change.method is 'apply'
      stack = @findStackFromStackId change.payload.stackId
      @reloadIDE stack.machines.first

    debug '[Kloud:API]', change


  # Follow Payment changes
  bindPaymentEvents: ->

    { groupsController } = kd.singletons

    disabled = isGroupDisabled()

    # /cc @cihangir: not sure if this is the right way to bind the event.
    groupsController.on 'payment_status_changed', =>
      @storage.initialize()


  cloneTemplate: (stackTemplate) ->

    return  unless stackTemplate

    unless canCreateStacks()
      return showError 'You are not allowed to create/edit stacks!'

    stackTemplate.clone (err, clonedTemplate) ->
      return  if showError err

      if clonedTemplate
        { reactor, router } = kd.singletons
        Tracker.track Tracker.STACKS_CLONED_TEMPLATE
        reactor.dispatch 'UPDATE_STACK_TEMPLATE_SUCCESS', { stackTemplate }
        router.handleRoute "/Stack-Editor/#{clonedTemplate.getId()}"
      else
        showError 'Failed to clone stack'
