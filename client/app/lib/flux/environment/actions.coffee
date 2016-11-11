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
environmentDataProvider = require 'app/userenvironmentdataprovider'
globals = require 'globals'
Machine = require 'app/providers/machine'
providersParser = require 'app/util/stacks/providersparser'
requirementsParser = require 'app/util/stacks/requirementsparser'
generateStackTemplateTitle = require 'app/util/generateStackTemplateTitle'
Tracker = require 'app/util/tracker'
$ = require 'jquery'

_eventsCache = { machine: {}, stack: no }

_bindMachineEvents = (environmentData) ->

  { reactor, computeController } = kd.singletons

  machines = reactor.evaluate getters.machinesWithWorkspaces

  computeController.ready ->

    machines.map (machine, id) ->
      return  if _eventsCache.machine[id]

      _eventsCache.machine[id] = yes

      publicHandler = (event) ->
        reactor.dispatch actions.MACHINE_UPDATED, { id, event }
      computeController.off "public-#{id}", publicHandler
      computeController.on  "public-#{id}", publicHandler

      reviveHandler = (newMachine) ->
        return loadMachines()  unless newMachine
        reactor.dispatch actions.MACHINE_UPDATED, { id, machine: newMachine }
      computeController.off "revive-#{id}", reviveHandler
      computeController.on  "revive-#{id}", reviveHandler

      if stack = computeController.findStackFromMachineId id
        applyHandler = (event) ->
          reactor.dispatch actions.MACHINE_UPDATED, { id, event }

        computeController.off "apply-#{stack._id}", applyHandler
        computeController.on  "apply-#{stack._id}", applyHandler


_bindStackEvents = ->

  return  if _eventsCache.stack is yes

  _eventsCache.stack = yes

  { reactor, computeController } = kd.singletons

  computeController.ready ->

    computeController.on 'StackRevisionChecked', (stack) ->
      return  if _revisionStatus?.error? and not stack._revisionStatus.status

      loadMachines().then ->
        reactor.dispatch actions.STACK_UPDATED, stack

    computeController.on 'GroupStacksInconsistent', ->
      reactor.dispatch actions.GROUP_STACKS_INCONSISTENT

    computeController.on 'GroupStacksConsistent', ->
      reactor.dispatch actions.GROUP_STACKS_CONSISTENT

    computeController.checkGroupStacks()


_bindTemplateEvents = (stackTemplate) ->

  { reactor, computeController } = kd.singletons

  { _id: id } = stackTemplate

  stackTemplate.on 'update', ->
    computeController.checkRevisonFromOriginalStackTemplate stackTemplate._id, yes
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

  remote.api.JMachine.one machineUId, (err, machine) ->
    if err
      showError err
    else if machine?
      callback machine


loadMachines = do (isPayloadUsed = no) -> ->

  { reactor } = kd.singletons

  reactor.dispatch actions.LOAD_USER_ENVIRONMENT_BEGIN

  new Promise (resolve, reject) ->

    kallback = (err, data) ->
      if err
        reactor.dispatch actions.LOAD_USER_ENVIRONMENT_FAIL, { err }
        reject err
      else
        reactor.dispatch actions.LOAD_USER_ENVIRONMENT_SUCCESS, data
        resolve data
        _bindMachineEvents data

    if environmentDataProvider.hasData() and not isPayloadUsed
      isPayloadUsed   = yes
      environmentData = environmentDataProvider.get()

      # If there are any collaboration machines, fetch all machines data from server.
      # Because `_globals` doesn't give workspace data of collaboration machines.
      # Ping @senthil for the best solution.
      if environmentData.collaboration.length
        return environmentDataProvider.fetch (data) -> kallback null, data

      return kd.utils.defer ->
        environmentDataProvider.revive()
        kallback null, environmentData

    environmentDataProvider.fetch (data) -> kallback null, data


loadStacks = (force = no) ->

  { reactor, computeController } = kd.singletons

  reactor.dispatch actions.LOAD_USER_STACKS_BEGIN

  new Promise (resolve, reject) ->

    computeController.fetchStacks (err, stacks) ->
      if err
        reactor.dispatch actions.LOAD_USER_STACKS_FAIL, { err }
        reject err
      else
        stacks.map (stack) ->
          stack.title = Encoder.htmlDecode stack.title
        reactor.dispatch actions.LOAD_USER_STACKS_SUCCESS, stacks
        resolve stacks
        _bindStackEvents()
    , force


rejectInvitation = (machine) ->

  kd.singletons.machineShareManager.unset machine.get 'uid'

  isApproved      = machine.get 'isApproved'
  isPermanent     = machine.get 'isPermanent'
  denyMachine     = switch machine.get 'type'
    when 'shared'         then isPermanent
    when 'collaboration'  then not isPermanent

  ideApp = environmentDataProvider.getIDEFromUId machine.get('uid')

  async.series([
    (callback) ->

      if denyMachine
        remote.revive(machine.toJS()).deny (err) ->
          showError err  if err
          callback err
      else
        callback()

    (callback) ->

      return callback()  unless machine.get('type') is 'collaboration'

      # Do not call social api from here if there is an ide app instance.
      # Because it will be called it in next queue item by "quit()" method instead of this queue.
      # You can check "stopCollaborationSession" method of collaborationcontroller.coffee
      # ~TURUNC
      return callback()  if ideApp and denyMachine

      { channel } = kd.singletons.socialapi
      workspace   = machine.get('workspaces').first()
      channelId   = workspace.get 'channelId'

      channel.byId { id: channelId }, (err, socialChannel) ->
        if err
          showError err
          return callback err

        isApproved = socialChannel.isParticipant
        method     = if isApproved then 'leave' else 'rejectInvite'

        channel[method] { channelId }, (err) ->
          showError err  if err
          callback()

    (callback) ->

      { reactor } = kd.singletons
      workspaces  = machine.get('workspaces')

      workspaces.map (workspace) ->
        reactor.dispatch actions.WORKSPACE_DELETED, {
          workspaceId : workspace.get '_id'
          machineId   : machine.get '_id'
        }

      callback()

    (callback) ->

      ideApp?.quit()  if denyMachine

      actionType = if machine.get('type') is 'collaboration'
      then 'COLLABORATION_INVITATION_REJECTED'
      else 'SHARED_VM_INVITATION_REJECTED'

      kd.singletons.reactor.dispatch actions[actionType], machine.get '_id'
      kd.singletons.computeController.reset callback

  ])


acceptInvitation = (machine) ->

  { router, machineShareManager, socialapi, reactor } = kd.singletons

  uid = machine.get 'uid'

  invitation  = machineShareManager.get uid
  machineShareManager.unset uid

  jMachine    = remote.revive machine.toJS()

  jMachine.approve (err) ->

    return showError err  if err

    kallback = (route, callback) ->
      # Fetch all machines
      loadMachines().then ->
        callback()
        router.handleRoute route

    if invitation?.type is 'collaboration' or machine.get('type') is 'collaboration'
      _getInvitationChannelId { uid, invitation }, (channelId) ->
        require('app/flux/socialapi/actions/channel').loadChannel(channelId).then ({ channel }) ->
          if channel.isParticipant
            return kallback "/IDE/#{channelId}", ->
              reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'

          socialapi.channel.acceptInvite { channelId }, (err) ->
            return showError err  if err

            kallback "/IDE/#{channelId}", ->
              reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'
    else
      kallback "/IDE/#{machine.get 'uid'}", ->
        reactor.dispatch actions.INVITATION_ACCEPTED, machine.get '_id'


dispatchCollaborationInvitationRejected = (id) ->

  kd.singletons.reactor.dispatch actions.COLLABORATION_INVITATION_REJECTED, id


dispatchSharedVMInvitationRejected = (id) ->

  kd.singletons.reactor.dispatch actions.SHARED_VM_INVITATION_REJECTED, id


_getInvitationChannelId = ({ uid, invitation }, callback) ->

  environmentDataProvider.fetchMachineByUId uid, (machine, workspaces) ->
    for workspace in workspaces

      if invitation?.workspaceId is workspace.getId()
        callback workspace.channelId
        break
      else if not invitation and workspace.channelId
        callback workspace.channelId
        break


showAddWorkspaceView = (machineId) ->

  kd.singletons.reactor.dispatch actions.SHOW_ADD_WORKSPACE_VIEW, machineId


hideAddWorkspaceView = (machineId) ->

  kd.singletons.reactor.dispatch actions.HIDE_ADD_WORKSPACE_VIEW, machineId


deleteWorkspace = (params) ->

  { machine, workspace, deleteRelatedFiles }  = params
  { router, appManager, reactor }             = kd.singletons
  { machineUId, rootPath, machineLabel, _id } = workspace.toJS()

  new Promise (resolve, reject) ->

    remote.api.JWorkspace.deleteById _id, (err) ->

      if err
        reactor.dispatch actions.WORKSPACE_DELETED_FAIL
        reject err
        return

      if deleteRelatedFiles
        methodName = 'deleteWorkspaceRootFolder'
        ideApp = environmentDataProvider.getIDEFromUId machineUId
        ideApp?[methodName] machineUId, rootPath

      reactor.dispatch actions.WORKSPACE_DELETED, {
        workspaceId : _id
        machineId   : machine.get '_id'
      }

      resolve()


setSelectedWorkspaceId = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.WORKSPACE_SELECTED, workspaceId


setSelectedMachineId = (machineId) ->

  kd.singletons.reactor.dispatch actions.MACHINE_SELECTED, machineId


setSelectedTemplateId = (templateId) ->

  kd.singletons.reactor.dispatch actions.SET_SELECTED_TEMPLATE_ID, { id: templateId }


setActiveStackId = (stackId) ->

  kd.utils.defer ->
    kd.singletons.reactor.dispatch actions.STACK_IS_ACTIVE, stackId


showDeleteWorkspaceWidget = (workspaceId) ->

  kd.singletons.reactor.dispatch actions.SHOW_DELETE_WORKSPACE_WIDGET, workspaceId


hideDeleteWorkspaceWidget = ->

  kd.singletons.reactor.dispatch actions.HIDE_DELETE_WORKSPACE_WIDGET


showManagedMachineAddedModal = (info, id) ->

  kd.singletons.reactor.dispatch actions.SHOW_MANAGED_MACHINE_ADDED_MODAL, {
    id
    info
  }


hideManagedMachineAddedModal = (id) ->

  kd.singletons.reactor.dispatch actions.HIDE_MANAGED_MACHINE_ADDED_MODAL, { id }


reinitStack = (stackId) ->

  { reactor } = kd.singletons

  reactor.dispatch actions.REMOVE_STACK, stackId

  if reactor.evaluate ['DifferentStackResourcesStore']
    reactor.dispatch actions.GROUP_STACKS_CONSISTENT


reinitStackFromWidget = (stack) ->

  { computeController } = kd.singletons

  new Promise (resolve, reject) ->

    stack = if stack then stack.toJS() else computeController.getGroupStack()

    computeController.reinitStack stack, (err) ->
      if err then reject(err) else resolve()


createWorkspace = (machine, workspace) ->

  kd.singletons.reactor.dispatch actions.WORKSPACE_CREATED, { machine, workspace }


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


loadTeamStackTemplates = ->

  { reactor } = kd.singletons

  query = { group: getGroup().slug }

  reactor.dispatch actions.LOAD_TEAM_STACK_TEMPLATES_BEGIN, { query }

  remote.api.JStackTemplate.some query, { limit: 30 }, (err, templates) ->

    if err
      return reactor.dispatch actions.LOAD_TEAM_STACK_TEMPLATES_FAIL, { query, err }

    templates = templates.filter (t) -> t.accessLevel is 'group'

    reactor.dispatch actions.LOAD_TEAM_STACK_TEMPLATES_SUCCESS, { query, templates }

    templates.forEach (template) -> _bindTemplateEvents template


loadPrivateStackTemplates = ->

  { reactor } = kd.singletons

  query = { group: getGroup().slug, originId: whoami()._id }

  reactor.dispatch actions.LOAD_PRIVATE_STACK_TEMPLATES_BEGIN, { query }

  remote.api.JStackTemplate.some query, { limit: 30 }, (err, templates) ->

    if err
      reactor.dispatch actions.LOAD_PRIVATE_STACK_TEMPLATES_FAIL, { query, err }

    templates = templates.filter (t) -> t.accessLevel is 'private'

    reactor.dispatch actions.LOAD_PRIVATE_STACK_TEMPLATES_SUCCESS, { query, templates }

    templates.forEach (template) -> _bindTemplateEvents template


setMachineAlwaysOn = (machineId, state) ->

  { computeController, reactor } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  reactor.dispatch actions.SET_MACHINE_ALWAYS_ON_BEGIN, { id : machineId, state }

  computeController.fetchUserPlan (plan) ->

    computeController.setAlwaysOn machine, state, (err) ->

      unless err
        return reactor.dispatch actions.SET_MACHINE_ALWAYS_ON_SUCCESS, { id : machineId }

      if err.name is 'UsageLimitReached' and plan isnt 'hobbyist'
        ComputeErrorUsageModal = require 'app/providers/computeerrorusagemodal'
        kd.utils.defer -> new ComputeErrorUsageModal { plan }
      else
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
    throw 'Provider doesn\'t have stack template!'

  { json: template, yaml: rawContent } = provider.defaultTemplate

  requiredProviders = providersParser template
  requiredProviders.push selectedProvider
  requiredData      = requirementsParser template

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
    config: { requiredData, requiredProviders }
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
    computeController.fetchStackTemplate stackTemplateId, (err, stackTemplate) ->
      return reject(err)  if err

      generateStackFromTemplate stackTemplate
        .then ({ stack, template }) ->
          { results : { machines } } = stack
          [ machine ] = machines
          computeController.reset yes, ->
            computeController.reloadIDE machine.obj.slug
            new kd.NotificationView { title: 'Stack generated successfully' }
            resolve({ stack, template })
        .catch (err) ->
          showError err
          reject(err)


generateStackFromTemplate = (template) ->

  { reactor } = kd.singletons

  return new Promise (resolve, reject) ->

    reactor.dispatch actions.GENERATE_STACK_BEGIN, { template }

    template.generateStack (err, stack) ->
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

  { reactor, groupsController } = kd.singletons

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

    appManager.quitByName 'IDE', ->
      computeController.destroyStack _stack, (err) ->
        return  if showError err

        reactor.dispatch actions.REMOVE_STACK, _stack._id

        computeController
          .reset yes
          .once 'RenderStacks', ->
            loadTeamStackTemplates()  unless teamStackTemplatesStore.size
            router.handleRoute '/IDE'

      , followEvents = no


changeTemplateTitle = (id, value) ->

  return  unless id

  { reactor } = kd.singletons

  reactor.dispatch actions.CHANGE_TEMPLATE_TITLE, { id, value }


loadMachineSharedUsers = (machineId) ->

  { computeController, reactor } = kd.singletons

  machine = computeController.findMachineFromMachineId machineId
  return  unless machine

  machine.jMachine.reviveUsers { permanentOnly : yes }, (err, users = []) ->
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
        computeController.triggerReviveFor machine._id
        return reject err  if err
        resolve newLabel

cloneStackTemplate = (template, revive) ->

  new kd.NotificationView { title:'Cloning Stack Template' }

  { reactor } = kd.singletons
  template = remote.revive template  if revive

  template.clone (err, stackTemplate) ->
    if err
      return new kd.NotificationView
        title: 'Error occured while cloning template'

    Tracker.track Tracker.STACKS_CLONED_TEMPLATE
    reactor.dispatch actions.UPDATE_STACK_TEMPLATE_SUCCESS, { stackTemplate }
    kd.singletons.router.handleRoute "/Stack-Editor/#{stackTemplate._id}"

loadExpandedMachineLabel = (label) ->

  { reactor } = kd.singletons
  reactor.dispatch actions.LOAD_EXPANDED_MACHINE_LABEL_SUCCESS, { label }


module.exports = {
  loadMachines
  loadStacks
  rejectInvitation
  acceptInvitation
  showAddWorkspaceView
  hideAddWorkspaceView
  deleteWorkspace
  setSelectedWorkspaceId
  setSelectedMachineId
  setSelectedTemplateId
  showDeleteWorkspaceWidget
  hideDeleteWorkspaceWidget
  showManagedMachineAddedModal
  hideManagedMachineAddedModal
  reinitStack
  createWorkspace
  setMachineListItem
  unsetMachineListItem
  handleMemberWarning
  handleSharedMachineInvitation
  setActiveInvitationMachineId
  setActiveLeavingSharedMachineId
  reinitStackFromWidget
  setActiveStackId
  dispatchCollaborationInvitationRejected
  dispatchSharedVMInvitationRejected
  loadTeamStackTemplates
  loadPrivateStackTemplates
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
  cloneStackTemplate
  loadExpandedMachineLabel
}
