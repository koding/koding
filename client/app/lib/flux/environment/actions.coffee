debug = (require 'debug') 'environment:actions'
_ = require 'lodash'
kd = require 'kd'
async = require 'async'
actions = require './actiontypes'
getters = require './getters'
Promise = require 'bluebird'
Encoder = require 'htmlencode'
remote = require 'app/remote'
Promise = require 'bluebird'
showError = require 'app/util/showError'
toImmutable = require 'app/util/toImmutable'
getGroup = require 'app/util/getGroup'
whoami = require 'app/util/whoami'
globals = require 'globals'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'
Tracker = require 'app/util/tracker'
$ = require 'jquery'
canCreateStacks = require 'app/util/canCreateStacks'
_eventsCache = { machine: {}, stack: no }


_bindMachineEvents = (machine) ->

  return  unless id = machine?._id

  { computeController, reactor } = kd.singletons

  if handler = _eventsCache.machine[id]
    return computeController.off "revive-#{id}", handler

  _eventsCache.machine[id] = handler = (newMachine) ->
    reactor.dispatch actions.MACHINE_UPDATED, { id, machine: newMachine }

  computeController.on "revive-#{id}", handler


_bindStackEvents = ->

  return  if _eventsCache.stack is yes

  _eventsCache.stack = yes

  { reactor, computeController } = kd.singletons

  computeController.on 'StackRevisionChecked', (stack) ->
    reactor.dispatch actions.STACK_UPDATED, stack

  computeController.on 'GroupStacksInconsistent', ->
    reactor.dispatch actions.GROUP_STACKS_INCONSISTENT

  computeController.on 'GroupStacksConsistent', ->
    reactor.dispatch actions.GROUP_STACKS_CONSISTENT


_bindTemplateEvents = (stackTemplate) ->

  unless stackTemplate
    console.warn 'null data passed to _bindTemplateEvents!'
    return

  { reactor, computeController } = kd.singletons

  { _id: id } = stackTemplate

  stackTemplate.on 'update', ->
    debug 'stack template updated', stackTemplate
    if stackTemplate.accessLevel is 'group'
      computeController.checkRevisionFromOriginalStackTemplate stackTemplate

  stackTemplate.on 'deleteInstance', ->
    reactor.dispatch actions.REMOVE_STACK_TEMPLATE_SUCCESS, { id }


handleMemberWarning = (message) ->

  console.warn '[member:warning]', message


handleSharedMachineInvitation = (sharedMachine) ->

  # Inconsistent property definition.
  { machineUId, uid } = sharedMachine

  fetchMachineByUId (machineUId or uid), (machine) ->
    machine = toImmutable machine
    setActiveInvitationMachineId { machine, forceUpdate: yes }
    setActiveLeavingSharedMachineId null


fetchMachineByUId = (machineUId, callback) ->

  remote.api.JMachine.one { uid: machineUId }, (err, machine) ->
    if err
      showError err
    else if machine?
      callback machine


loadMachines = do (isPayloadUsed = no) -> ->

  { reactor, computeController } = kd.singletons
  reactor.dispatch actions.LOAD_USER_ENVIRONMENT_BEGIN

  new Promise (resolve, reject) ->

    computeController.ready ->

      machines = computeController.storage.machines.get()

      reactor.dispatch actions.LOAD_USER_ENVIRONMENT_SUCCESS, machines

      machines.forEach _bindMachineEvents

      resolve machines


loadStacks = (force = no) ->

  { reactor, computeController } = kd.singletons

  reactor.dispatch actions.LOAD_USER_STACKS_BEGIN

  new Promise (resolve, reject) ->

    computeController.ready ->

      stacks = computeController.storage.stacks.get()

      reactor.dispatch actions.LOAD_USER_STACKS_SUCCESS, stacks
      resolve stacks
      _bindStackEvents()


dispatchInvitationRejected = (id) ->

  kd.singletons.reactor.dispatch actions.INVITATION_REJECTED, id


_getInvitationChannelId = ({ uid }, callback) ->

  machine = kd.singletons.computeController.storage.machines.get 'uid', uid
  callback if machine then machine.getChannelId() else null


setSelectedMachineId = (machineId) ->

  kd.singletons.reactor.dispatch actions.MACHINE_SELECTED, machineId


setSelectedTemplateId = (templateId) ->

  kd.singletons.reactor.dispatch actions.SET_SELECTED_TEMPLATE_ID, { id: templateId }


setActiveStackId = (stackId) ->

  kd.utils.defer ->
    kd.singletons.reactor.dispatch actions.STACK_IS_ACTIVE, stackId


showManagedMachineAddedModal = (info, id) ->

  kd.singletons.reactor.dispatch actions.SHOW_MANAGED_MACHINE_ADDED_MODAL, {
    id
    info
  }


hideManagedMachineAddedModal = (id) ->

  kd.singletons.reactor.dispatch actions.HIDE_MANAGED_MACHINE_ADDED_MODAL, { id }


checkTeamStack = (stackId) ->

  { reactor } = kd.singletons
  if reactor.evaluate ['DifferentStackResourcesStore']
    reactor.dispatch actions.GROUP_STACKS_CONSISTENT


reinitStackFromWidget = (stack) ->

  { computeController } = kd.singletons

  new Promise (resolve, reject) ->

    stack = if stack then stack.toJS()

    computeController.reinitStack stack, (err) ->
      if err then reject(err) else resolve()


setMachineListItem = (id, machineListItem) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.MACHINE_LIST_ITEM_CREATED, { id, machineListItem }


unsetMachineListItem = (id, machineListItem) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.MACHINE_LIST_ITEM_DELETED, { id, machineListItem }


setActiveInvitationMachineId = (options = {}) ->

  { machine, forceUpdate }  = options
  { reactor }               = kd.singletons

  id = null

  if machine
    id = machine.get '_id'
    id = null  if machine.get('type') is 'own'
    id = null  if machine.get('isApproved')

  reactor.dispatch actions.SET_ACTIVE_INVITATION_MACHINE_ID, { id, forceUpdate }


setActiveLeavingSharedMachineId = (id) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.SET_ACTIVE_LEAVING_SHARED_MACHINE_ID, { id }


loadStackTemplates = ->

  { reactor } = kd.singletons

  reactor.dispatch actions.LOAD_TEAM_STACK_TEMPLATES_BEGIN,    {}
  reactor.dispatch actions.LOAD_PRIVATE_STACK_TEMPLATES_BEGIN, {}

  kd.singletons.computeController.fetchStackTemplates (err, templates) ->

    if err
      reactor.dispatch actions.LOAD_TEAM_STACK_TEMPLATES_FAIL,    { err }
      reactor.dispatch actions.LOAD_PRIVATE_STACK_TEMPLATES_FAIL, { err }
      return

    teamTemplates    = templates.filter (t) -> t.accessLevel is 'group'
    privateTemplates = templates.filter (t) -> (t.originId is whoami()._id) and (t.accessLevel is 'private')

    reactor.dispatch actions.LOAD_TEAM_STACK_TEMPLATES_SUCCESS,    { templates: teamTemplates }
    reactor.dispatch actions.LOAD_PRIVATE_STACK_TEMPLATES_SUCCESS, { templates: privateTemplates }

    templates.forEach (template) -> _bindTemplateEvents template


setMachineAlwaysOn = (machineId, state) ->

  { computeController, reactor } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  reactor.dispatch actions.SET_MACHINE_ALWAYS_ON_BEGIN, { id : machineId, state }

  computeController.setAlwaysOn machine, state, (err) ->

    unless err
      return reactor.dispatch actions.SET_MACHINE_ALWAYS_ON_SUCCESS, { id : machineId }

    showError err
    reactor.dispatch actions.SET_MACHINE_ALWAYS_ON_FAIL, { id : machineId }


setMachinePowerStatus = (machineId, shouldStart) ->

  { computeController } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  method = if shouldStart then 'start' else 'stop'

  kd.singletons.computeController[method] machine


createStackTemplate = (options) ->

  { reactor } = kd.singletons

  { title, template, credentials, rawContent
    templateDetails, config, description } = options

  return new Promise (resolve, reject) ->

    reactor.dispatch actions.CREATE_STACK_TEMPLATE_BEGIN

    remote.api.JStackTemplate.create {
      title, template, credentials, rawContent
      templateDetails, config, description
    }, (err, stackTemplate) ->
      if err
        reactor.dispatch actions.CREATE_STACK_TEMPLATE_FAIL, { err }
        reject err
        return

      reactor.dispatch actions.CREATE_STACK_TEMPLATE_SUCCESS, { stackTemplate }
      _bindTemplateEvents stackTemplate
      resolve { stackTemplate }


createStackTemplateWithDefaults = (selectedProvider) ->

  Providers = globals.config.providers
  provider  = Providers[selectedProvider]

  unless provider?.defaultTemplate
    throw { message: 'Provider doesn\'t have stack template!' }

  { json: template, yaml: rawContent } = provider.defaultTemplate

  stackData = {
    template
    rawContent
    title: generateStackTemplateTitle selectedProvider
    description: '''
      ###### Stack Template Readme

      You can write a readme for this stack template here.
      It will be displayed whenever a user attempts to build this stack.
      You can use markdown within the readme content.

    '''
    credentials: {}
    templateDetails: null
  }

  return createStackTemplate stackData


updateStackTemplate = (stackTemplate, options) ->

  { reactor } = kd.singletons

  { inuse, _updated } = stackTemplate

  { machines, config, title, template, credentials
    rawContent, templateDetails, description } = options

  updateOptions = if machines
  then { machines, config }
  else { title, template, credentials, rawContent, templateDetails, config, description }

  return new Promise (resolve, reject) ->

    reactor.dispatch actions.UPDATE_STACK_TEMPLATE_BEGIN

    stackTemplate.update updateOptions, (err, updatedTemplate) ->
      if err
        reactor.dispatch actions.UPDATE_STACK_TEMPLATE_FAIL, { err }
        reject err
        return

      stackTemplate = _.assign stackTemplate, { inuse, _updated }

      updateStackTemplate.inuse = inuse

      successPayload = { stackTemplate: updatedTemplate }

      reactor.dispatch actions.UPDATE_STACK_TEMPLATE_SUCCESS, successPayload
      _bindTemplateEvents updatedTemplate
      resolve successPayload


fetchAndUpdateStackTemplate = (templateId) ->

  { computeController, reactor } = kd.singletons
  reactor.dispatch actions.UPDATE_STACK_TEMPLATE_BEGIN

  new Promise (resolve, reject) ->
    computeController.fetchStackTemplate templateId, (err, stackTemplate) ->
      if err
        reactor.dispatch actions.UPDATE_STACK_TEMPLATE_FAIL, { err }
        reject err
        return

      reactor.dispatch actions.UPDATE_STACK_TEMPLATE_SUCCESS, { stackTemplate }
      _bindTemplateEvents stackTemplate
      resolve stackTemplate

generateStack = (stackTemplateId) ->

  { computeController } = kd.singletons

  new Promise (resolve, reject) ->

    stackTemplate = computeController.storage.templates.get '_id', stackTemplateId
    return reject new Error 'StackTemplate not found'  unless stackTemplate

    generateStackFromTemplate stackTemplate
      .then resolve
      .catch reject

generateStackFromTemplate = (template) ->

  { reactor } = kd.singletons

  return new Promise (resolve, reject) ->

    reactor.dispatch actions.GENERATE_STACK_BEGIN, { template }

    template.generateStack { verify: yes }, (err, stack) ->
      if err
        reactor.dispatch actions.GENERATE_STACK_FAIL, { template, err }
        reject err
        return

      reactor.dispatch actions.GENERATE_STACK_SUCCESS, { template, stack }
      resolve { template, stack }


disconnectMachine = (machine) ->

  { computeController } = kd.singletons
  machine = computeController.findMachineFromMachineId machine.get '_id'
  computeController.destroy machine


removeStackTemplate = (stackTemplate) ->

  { reactor, groupsController, computeController } = kd.singletons

  currentGroup = groupsController.getCurrentGroup()

  return new Promise (resolve, reject) ->
    reactor.dispatch actions.REMOVE_STACK_TEMPLATE_BEGIN, { stackTemplate }
    stackTemplate.delete (err) ->

      if err
        reactor.dispatch actions.REMOVE_STACK_TEMPLATE_FAIL, { stackTemplate, err }
        reject err
        return

      if stackTemplate.accessLevel is 'group'
        currentGroup.sendNotification 'GroupStackTemplateRemoved', stackTemplate._id

      computeController.storage.templates.pop stackTemplate

      reactor.dispatch actions.REMOVE_STACK_TEMPLATE_SUCCESS, { id: stackTemplate._id }
      resolve()

      Tracker.track Tracker.STACKS_DELETE_TEMPLATE


deleteStack = ({ stackTemplateId, stack }) ->

  { computeController, appManager, router, reactor } = kd.singletons

  teamStackTemplatesStore = reactor.evaluate(['TeamStackTemplatesStore'])

  _stack = remote.revive stack.toJS()  if stack

  if not _stack and stackTemplateId
    _stack = computeController.findStackFromTemplateId stackTemplateId

  return  unless _stack

  computeController.ui.askFor 'deleteStack', {}, (status) ->
    return  unless status.confirmed

    computeController.destroyStack _stack, (err) ->
      return  if showError err
      reactor.dispatch actions.REMOVE_STACK, _stack._id
    , followEvents = no


changeTemplateTitle = (id, value) ->

  return  unless id

  { reactor } = kd.singletons

  reactor.dispatch actions.CHANGE_TEMPLATE_TITLE, { id, value }


loadMachineSharedUsers = (machineId) ->

  { computeController, reactor } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  machine.reviveUsers { permanentOnly : yes }, (err, users = []) ->
    reactor.dispatch actions.LOAD_MACHINE_SHARED_USERS, { id : machineId, users }


shareMachineWithUser = (machineId, nickname) ->

  { computeController } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  remote.api.SharedMachine.add machine.uid, [nickname], (err) ->

    return showError err  if err

    kite = machine.getBaseKite()
    kite.klientShare { username: nickname, permanent: yes }
      .then -> loadMachineSharedUsers machineId
      .catch (err) ->
        showError err  unless err.message is 'user is already in the shared list.'


unshareMachineWithUser = (machineId, nickname) ->

  { computeController } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  remote.api.SharedMachine.kick machine.uid, [nickname], (err) ->

    return showError err  if err

    kite = machine.getBaseKite()
    kite.klientUnshare { username: nickname, permanent: yes }
      .then -> loadMachineSharedUsers machineId
      .catch (err) ->
        showError err  unless err.message is 'user is not in the shared list.'


unshareMachineWithAllUsers = (machineId) ->

  machine = kd.singletons.reactor.evaluate ['MachinesStore', machineId]

  new Promise (resolve, reject) ->
    queue = machine.get('sharedUsers').toJS().map (user) -> (next) ->
      { nickname } = user.profile
      unshareMachineWithUser(machineId, nickname)
        .then -> next(null)
        .catch (err) -> next(err)

    async.series queue, (err) -> if err then reject() else resolve()

setLabel = (machineUId, label) ->

  { computeController } = kd.singletons

  new Promise (resolve, reject) ->
    fetchMachineByUId machineUId, (machine) ->
      machine.setLabel label, (err, newLabel) ->
        # FIXME this shouldn't be necessary
        computeController.triggerReviveFor machine._id
        return reject err  if err
        resolve newLabel


loadExpandedMachineLabel = (label) ->

  { reactor } = kd.singletons
  reactor.dispatch actions.LOAD_EXPANDED_MACHINE_LABEL_SUCCESS, { label }


# Following are here for now, will be moved to appropriate place afterwards.
# ~Umut

leaveMachine = (machine) ->

  { reactor, appManager, computeController } = kd.singletons

  ideInstance = appManager.getInstance 'IDE', 'mountedMachineUId', machine.uid

  async.series([

    (callback) ->

      machine.deny (err) ->
        showError err  if err
        callback err

    (callback) ->

      ideInstance?.quit reload = no

      machineId = machine.getId()
      reactor.dispatch actions.INVITATION_REJECTED, machineId
      computeController.storage.machines.pop machineId

  ])


acceptInvitation = (machine) ->

  { router, computeController, socialapi } = kd.singletons

  debug 'acceptInvitation', { machine }

  approveMachine = (m) ->
    new Promise (resolve, reject) ->
      m.approve (err) ->
        if err then reject(err) else resolve(m)

  approveMachine machine
    .then ->
      # permanently shared machines doesn't have a channel id, skip this part.
      unless machine.getType() is 'collaboration'
        return Promise.resolve()

      unless channelId = machine.getChannelId()
        return Promise.reject new Error 'Session is invalid or ended by host'

      require('app/flux/socialapi/actions/channel').loadChannel channelId
        .then ({ channel }) ->
          if channel.isParticipant
          then Promise.resolve()
          else socialapi.channel.acceptInvite { channelId: channel._id }

    .then ->
      machine.setApproved()
      computeController.storage.machines.push '_id', machine

    .then ->
      kd.singletons.router.handleRoute "/IDE/#{machine.uid}"

    .then ->
      Tracker.track Tracker.VM_REJECTED_SHARED

    .catch (err) ->
      showError err.message


module.exports = {
  loadMachines
  loadStacks
  leaveMachine
  acceptInvitation
  setSelectedMachineId
  setSelectedTemplateId
  showManagedMachineAddedModal
  hideManagedMachineAddedModal
  checkTeamStack
  setMachineListItem
  unsetMachineListItem
  handleMemberWarning
  handleSharedMachineInvitation
  setActiveInvitationMachineId
  setActiveLeavingSharedMachineId
  reinitStackFromWidget
  setActiveStackId
  dispatchInvitationRejected
  loadStackTemplates
  setMachineAlwaysOn
  setMachinePowerStatus
  createStackTemplate
  createStackTemplateWithDefaults
  updateStackTemplate
  generateStack
  generateStackFromTemplate
  removeStackTemplate
  deleteStack
  changeTemplateTitle
  loadMachineSharedUsers
  shareMachineWithUser
  unshareMachineWithUser
  unshareMachineWithAllUsers
  disconnectMachine
  setLabel
  fetchAndUpdateStackTemplate
  loadExpandedMachineLabel
}
